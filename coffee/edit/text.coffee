###
000000000  00000000  000   000  000000000
   000     000        000 000      000   
   000     0000000     00000       000   
   000     000        000 000      000   
   000     00000000  000   000     000   
###

{ keyinfo, stopEvent, post, elem, pos, log, _ } = require 'kxk'

{ itemMatrix } = require '../utils'

{ clipboard } = require 'electron'

class Text

    constructor: (@kali, @item) ->
        
        # this is not a tool!
        
        @stage = @kali.stage
        
        font = @item.font()
        bbox = @item.bbox()
        height = bbox.height 
        height = @item.data('height') if not height
        
        @element = elem 'div',      class:'textEdit'
        @input   = elem 'textarea', class:'textEditInput', rows: 10
        @input.style.fontFamily = font['font-family']
        @input.style.fontWeight = font['font-weight'] if font['font-weight']?
        @input.style.fontStyle  = font['font-style']  if font['font-style']?
        @input.style.fontSize   = "#{font['font-size']}px"
        @input.style.width      = "#{bbox.width+2}px"
        @input.style.height     = "#{height+2}px"
        @input.style.lineHeight = @item.leading()
        
        texts = []
        @item.lines().each (line) ->
            texts.push @text().trim()
        text = texts.join '\n'

        @input.value = text

        @input.style.textAlign = switch @item.font()['text-anchor']
            when 'start'    then 'left'
            when 'middle'   then 'center'
            when 'end'      then 'right'
            
        @updateTransform()
        
        @element.appendChild @input
        
        @select 'all'

        vbox = @stage.svg.viewbox()
        @element.style.transform = "translate(#{-vbox.x*vbox.zoom}px, #{-vbox.y*vbox.zoom}px) scale(#{vbox.zoom})"
        
        @kali.insertAboveSelection @element
        
        @input.addEventListener 'input',   @onInput
        @input.addEventListener 'keydown', @onKeyDown
        
        @input.focus()

        post.on 'stage', @onStage
            
    onStage: (action, vbox) =>

        if action == 'viewbox'
            @element.style.transform = "translate(#{-vbox.x*vbox.zoom}px, #{-vbox.y*vbox.zoom}px) scale(#{vbox.zoom})"
        
    del: ->

        post.removeListener 'stage', @onStage
        
        @element.remove()
        @input.remove()
        delete @element
        delete @input
            
    endEditing: ->
        
        @kali.focus()
        @stage.shapes.clearText()
        
    onInput: (event) => 
        @setText event.target.value
        
    # 000000000  00000000  000   000  000000000  
    #    000     000        000 000      000     
    #    000     0000000     00000       000     
    #    000     000        000 000      000     
    #    000     00000000  000   000     000     
    
    setText: (text) ->
        
        @item.text text
        bbox = @item.bbox()
        @input.style.width  = "#{bbox.width+2}px"
        @input.style.height = "#{bbox.height+2}px"
        
        @updateTransform()
                
    insertText: (text) ->
        
        start = @input.selectionStart
        @input.value = @input.value.slice(0, @input.selectionStart) + text + @input.value.slice @input.selectionEnd
        @input.selectionStart = start + text.length
        @input.selectionEnd   = start + text.length
        @setText @input.value

    # 000000000  00000000    0000000   000   000   0000000  00000000   0000000   00000000   00     00  
    #    000     000   000  000   000  0000  000  000       000       000   000  000   000  000   000  
    #    000     0000000    000000000  000 0 000  0000000   000000    000   000  0000000    000000000  
    #    000     000   000  000   000  000  0000       000  000       000   000  000   000  000 0 000  
    #    000     000   000  000   000  000   000  0000000   000        0000000   000   000  000   000  
    
    updateTransform: ->
        
        bbox = @item.bbox()
        matrix = itemMatrix @item
        switch @item.data('anchor')
            when 'middle', 'start', 'end'
                matrix = matrix.multiply new SVG.Matrix().translate bbox.x, bbox.y
            else
                fontSize = @item.font()['font-size']
                leading = @item.leading()
                switch (@item.font()['text-anchor'] ? 'start')
                    when 'start'  then matrix = matrix.multiply new SVG.Matrix().translate 0, leading.value*fontSize*0.2
                    when 'middle' then matrix = matrix.multiply new SVG.Matrix().translate -bbox.width/2, leading.value*fontSize*0.2
                    when 'end'    then matrix = matrix.multiply new SVG.Matrix().translate -bbox.width, leading.value*fontSize*0.2
        @input.style.transform = matrix.toString()
        
    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    select: (action) ->
        
        switch action
            when 'all'
                @input.selectionStart = 0
                @input.selectionEnd   = @input.value.length 
            when 'none'
                @input.selectionStart = @input.selectionEnd

    selectedText: -> @input.value.slice @input.selectionStart, @input.selectionEnd
                
    #  0000000  000   000  000000000  
    # 000       000   000     000     
    # 000       000   000     000     
    # 000       000   000     000     
    #  0000000   0000000      000     
    
    cutSelected: ->
        
        start = @input.selectionStart
        @input.value = @input.value.slice(0, @input.selectionStart) + @input.value.slice @input.selectionEnd
        @input.selectionStart = start
        @input.selectionEnd = start
        @setText @input.value
    
    cut: ->
        
        clipboard.writeText @selectedText()
        @cutSelected()
            
    copy: ->
            
        clipboard.writeText @selectedText()
            
    paste: -> 
        
        @cutSelected()
        @insertText clipboard.readText()
                
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event

        switch combo
            
            when 'ctrl+enter'
                
                v = @input.value
                v = v.slice(0, @input.selectionStart) + '\n' + v.slice @input.selectionEnd
                s = @input.selectionStart
                @input.value = v
                @input.selectionStart = s+1
                @input.selectionEnd   = s+1
                @setText v
                
            when 'ctrl+a' then stopEvent(event) and @select 'all'
            when 'ctrl+d' then stopEvent(event) and @select 'none'
            when 'ctrl+x' then stopEvent(event) and @cut()
            when 'ctrl+c' then stopEvent(event) and @copy()
            when 'ctrl+v' then stopEvent(event) and @paste()
                
            when 'esc', 'tab'

                @endEditing()
        
        if combo.startsWith 'ctrl' then return

        event.stopPropagation()
            
module.exports = Text

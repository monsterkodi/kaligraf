
# 000000000  00000000  000   000  000000000
#    000     000        000 000      000   
#    000     0000000     00000       000   
#    000     000        000 000      000   
#    000     00000000  000   000     000   

{ keyinfo, stopEvent, post, elem, pos, log, _ } = require 'kxk'

{ clipboard } = require 'electron'

class Text

    constructor: (@kali, @item) ->
        
        @stage = @kali.stage
        
        font = @item.font()
        bbox = @item.bbox()
        
        @element = elem 'div',      class:'textEdit'
        @input   = elem 'textarea', class:'textEditInput', rows: 10
        @input.style.fontFamily = font['font-family']
        @input.style.fontWeight = font['font-weight'] if font['font-weight']?
        @input.style.fontSize   = "#{font['font-size']}px"
        @input.style.width      = "#{bbox.width+100}px"
        @input.style.height     = "#{bbox.height*2}px"
        @input.style.color      = 'transparent'
        
        @element.appendChild @input

        m = @item.transform().matrix.translate bbox.x, bbox.y
        
        @input.style.transform = m.toString()
        @input.style.caretColor = @stage.foregroundColor()
        @input.value = @item.text()
        @select 'all'

        vbox = @stage.svg.viewbox()
        @element.style.transform = "translate(#{-vbox.x*vbox.zoom}px, #{-vbox.y*vbox.zoom}px) scale(#{vbox.zoom})"
        
        @kali.insertBelowTools @element
        
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
        
    onInput: (event) => @setText event.target.value
        
    # 000000000  00000000  000   000  000000000  
    #    000     000        000 000      000     
    #    000     0000000     00000       000     
    #    000     000        000 000      000     
    #    000     00000000  000   000     000     
    
    setText: (text) ->
        
        @item.text text
        bbox = @item.bbox()
        @input.style.width  = "#{bbox.width+100}px"
        @input.style.height = "#{bbox.height+200}px"

    insertText: (text) ->
        start = @input.selectionStart
        @input.value = @input.value.slice(0, @input.selectionStart) + text + @input.value.slice @input.selectionEnd
        @input.selectionStart = start
        @input.selectionEnd   = start + text.length
        @setText @input.value
        
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
            
            when 'enter'
                
                v = @input.value
                v = v.slice(0, @input.selectionStart) + '\n' + v.slice @input.selectionEnd
                s = @input.selectionStart
                @input.value = v
                @input.selectionStart = s+1
                @input.selectionEnd   = s+1
                @setText v
                
            when 'command+a' then stopEvent(event) and @select 'all'
            when 'command+d' then stopEvent(event) and @select 'none'
            when 'command+x' then stopEvent(event) and @cut()
            when 'command+c' then stopEvent(event) and @copy()
            when 'command+v' then stopEvent(event) and @paste()
                
            when 'esc', 'tab'

                @endEditing()
        
module.exports = Text

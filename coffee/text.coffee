
# 000000000  00000000  000   000  000000000
#    000     000        000 000      000   
#    000     0000000     00000       000   
#    000     000        000 000      000   
#    000     00000000  000   000     000   

{ keyinfo, post, elem, pos, log, _ } = require 'kxk'

class Text

    constructor: (@kali, @item) ->
        
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
        @input.value = @item.text()

        vbox = @kali.stage.svg.viewbox()
        @element.style.transform = "translate(#{-vbox.x*vbox.zoom}px, #{-vbox.y*vbox.zoom}px) scale(#{vbox.zoom})"
        
        @kali.insertBelowTools @element
        
        @input.addEventListener 'input',  @onInput
        @input.addEventListener 'keydown',  @onKeyDown
        
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
     
    onKeyDown: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        switch combo
            when 'enter'
                v = @input.value
                v = v.slice(0, @input.selectionStart) + '\n' + v.slice @input.selectionEnd
                s = @input.selectionStart
                @input.value = v
                @input.selectionStart = s+1
                @input.selectionEnd = s+1
                @setText v
            when 'esc'
                @kali.focus()
        
    onInput: (event) => @setText event.target.value
        
    setText: (text) ->
        
        @item.text text
        bbox = @item.bbox()
        @input.style.width  = "#{bbox.width+100}px"
        @input.style.height = "#{bbox.height+200}px"
        
module.exports = Text

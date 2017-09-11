
# 000000000  00000000  000   000  000000000
#    000     000        000 000      000   
#    000     0000000     00000       000   
#    000     000        000 000      000   
#    000     00000000  000   000     000   

{ elem, pos, log, _ } = require 'kxk'

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
        @input.style.height     = "#{bbox.height+100}px"
        @input.style.color      = @item.style 'fill'
        
        @element.appendChild @input

        m = @item.transform().matrix.translate bbox.x, bbox.y
        
        @input.style.transform = m.toString()
        @input.value = @item.text()

        vbox = @kali.stage.svg.viewbox()
        @element.style.transform = "translate(#{-vbox.x*vbox.zoom}px, #{-vbox.y*vbox.zoom}px) scale(#{vbox.zoom})"
        
        @kali.insertBelowTools @element
        
        @input.addEventListener 'input',  @onInput

    del: ->

        @element.remove()
        @input.remove()
        delete @element
        delete @input
        
    onInput: (event) =>
        
        log event.target.value
        @item.text event.target.value
        bbox = @item.bbox()
        @input.style.width = "#{bbox.width+100}px"
        @input.style.height = "#{bbox.height+100}px"

module.exports = Text

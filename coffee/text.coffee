
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
        
        @element = elem 'div',   class:'textEdit'
        @zoom    = elem 'div',   class:'textEditZoom'
        @input   = elem 'input', class:'textEditInput'
        @input.style.fontFamily = font['font-family']
        @input.style.fontWeight = font['font-weight'] if font['font-weight']?
        @input.style.fontSize   = "#{font['font-size']}px"
        @input.style.width      = "#{bbox.width}px"
        
        @zoom.appendChild @input
        @element.appendChild @zoom

        vb = @kali.stage.svg.viewbox()
        
        transform = @item.transform()
        s = new SVG.Matrix().scale vb.zoom 
        b = new SVG.Matrix().translate bbox.x, bbox.y
        m = @item.transform().matrix.multiply b
        
        @input.style.transform = m.toString()
        
        @input.value = @item.text()

        @element.style.transform = "translate(#{-vb.x*vb.zoom}px, #{-vb.y*vb.zoom}px)"
        @zoom.style.transform = "scale(#{vb.zoom})"
        
        @kali.insertBelowTools @element

    del: ->
        # log 'text del'
        @element.remove()
        @input.remove()
        delete @element
        delete @input

module.exports = Text

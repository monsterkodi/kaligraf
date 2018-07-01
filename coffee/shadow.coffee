###
 0000000  000   000   0000000   0000000     0000000   000   000
000       000   000  000   000  000   000  000   000  000 0 000
0000000   000000000  000000000  000   000  000   000  000000000
     000  000   000  000   000  000   000  000   000  000   000
0000000   000   000  000   000  0000000     0000000   00     00
###

{ log } = require 'kxk'

{ boundingBox } = require './utils'

class Shadow

    constructor: (@element) ->

        @svg = SVG(@element).size '100%', '100%'
        @svg.style 
            position: 'absolute'
            'pointer-events': 'none'
        
        @grp  = @svg.group()
        @brct = @grp.rect()
        
        @brct.style 
            fill:   'none'
            stroke: 'none'
        
        @rect = @grp.rect()

        @rect.style 
            fill:   '#000'
            'fill-opacity': 0.5
            
        @grp.filter (add) -> add.gaussianBlur 10
        
        @element.parentNode.insertBefore @svg.node, @element
        @update()
        
    update: ->
        
        @svg.style.display = @element.style.display
        br = boundingBox @element
        br.x -= 6
        br.y -= 30
        @svg.style
            left:   "#{br.x-30}px"
            top:    "#{br.y-30}px"
            width:  "#{br.w+60}px"
            height: "#{br.h+60}px"
            
        @brct.attr
            x:      0
            y:      0
            width:  br.w+60
            height: br.h+60
                        
        @rect.attr 
            x:      30
            y:      30
            width:  br.w
            height: br.h
            
module.exports = Shadow

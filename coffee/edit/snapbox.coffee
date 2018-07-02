###
 0000000  000   000   0000000   00000000   0000000     0000000   000   000
000       0000  000  000   000  000   000  000   000  000   000   000 000 
0000000   000 0 000  000000000  00000000   0000000    000   000    00000  
     000  000  0000  000   000  000        000   000  000   000   000 000 
0000000   000   000  000   000  000        0000000     0000000   000   000
###

{ log, _ } = require 'kxk'

class SnapBox

    constructor: () ->

    @svgElemAtPos: (kali, root, stagePos) ->
                
        tools = kali.tools
        trans = kali.trans
        
        g = root.group()
        
        r = g.rect '100%', '100%'
        r.radius tools.radius.radius
        r.style
            stroke:             tools.stroke.color
            'stroke-opacity':   tools.stroke.alpha
            'stroke-width':     tools.width.width
            'fill-opacity':     tools.fill.alpha
            fill:               tools.fill.color
        
        t = g.text 'Hello'
        t.leading 1.185
        t.font 'size',   10000
        t.font 'weight', tools.font.weight
        t.font 'style',  tools.font.style
        t.font 'family', tools.font.family
        t.font 'anchor', tools.anchor.anchor
        t.style
            'stroke-opacity':   0        
            'fill-opacity':     tools.stroke.alpha
            fill:               tools.stroke.color
        g
                
module.exports = SnapBox

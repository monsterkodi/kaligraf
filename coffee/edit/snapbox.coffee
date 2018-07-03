###
 0000000  000   000   0000000   00000000   0000000     0000000   000   000
000       0000  000  000   000  000   000  000   000  000   000   000 000 
0000000   000 0 000  000000000  00000000   0000000    000   000    00000  
     000  000  0000  000   000  000        000   000  000   000   000 000 
0000000   000   000  000   000  000        0000000     0000000   000   000
###

{ last, first, log, _ } = require 'kxk'

class SnapBox

    @setRect: (box, rect) ->
        
        r = first box.children()
        width = rect.x2 - rect.x
        height = rect.y2 - rect.y 
        log 'SnapBox.setRect', width, height
        r.size width, height
        t = last box.children()
        t.font 'size', height/2
        log 'anchor', t.data 'anchor'
        SnapBox.applyAnchor box
            
    @setAnchor: (box, anchor) ->
        
        t = last box.children()
        t.font 'anchor', anchor
        t.data 'anchor', anchor
        SnapBox.applyAnchor box
        
    @applyAnchor: (box) ->
        
        r = first box.children()
        t = last box.children()
        width = r.width()
        height = r.height()
        switch t.data 'anchor'
            when 'start'  then t.x Math.min height/2, width/10
            when 'middle' then t.x width/2
            when 'end'    then t.x width - Math.min height/2, width/10
            
    @svgElemAtPos: (kali, root, stagePos) ->
             
        tools = kali.tools
        trans = kali.trans
        
        g = root.group()
        
        g.data 'type', 'snapbox'
        
        r = g.rect '400', '100'
        r.radius tools.radius.radius
        r.style
            stroke:             tools.stroke.color
            'stroke-opacity':   tools.stroke.alpha
            'stroke-width':     tools.width.width
            'fill-opacity':     tools.fill.alpha
            fill:               tools.fill.color
        
        t = g.text 'Hello'
        t.font 'size',   50
        t.font 'weight', tools.font.weight
        t.font 'style',  tools.font.style
        t.font 'family', tools.font.family
        t.font 'anchor', tools.anchor.anchor
        t.data 'anchor', tools.anchor.anchor
        switch tools.anchor.anchor
            when 'start'  then t.x '40'
            when 'middle' then t.x '200'
            when 'end'    then t.x '360'
        t.style
            'stroke-opacity':   0        
            'fill-opacity':     tools.stroke.alpha
            fill:               tools.stroke.color
        g

module.exports = SnapBox

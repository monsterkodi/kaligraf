###
 0000000  000   000   0000000   00000000   0000000     0000000   000   000
000       0000  000  000   000  000   000  000   000  000   000   000 000 
0000000   000 0 000  000000000  00000000   0000000    000   000    00000  
     000  000  0000  000   000  000        000   000  000   000   000 000 
0000000   000   000  000   000  000        0000000     0000000   000   000
###

{ last, first, pos, log, _ } = require 'kxk'

{ itemMatrix } = require '../utils'

SnapLine = require './snapline'

class SnapBox

    @onStartDragDot: (kali, box, dot, event) ->
        
        new SnapLine kali, box, dot
    
    @closestTarget: (kali, box, stagePos) ->
        
        r = first box.children()
        p = [
            corner:'top left',   pos:pos 0,0
        ,
            corner:'top center', pos:pos r.width()/2, 0
        ,
            corner:'top right',  pos:pos r.width(), 0
        ,
            corner:'mid right',  pos:pos r.width(), r.height()/2
        ,
            corner:'bot right',  pos:pos r.width(), r.height()
        ,
            corner:'bot center', pos:pos r.width()/2, r.height()
        ,
            corner:'bot left',   pos:pos 0, r.height()
        ,
            corner:'mid left',   pos:pos 0, r.height()/2
        ,
            corner:'mid center', pos:pos r.width()/2, r.height()/2
        ]
        p = p.map (a) -> a.pos = kali.trans.fullTransform(r, a.pos); a
        p.sort (a,b) -> a.pos.distSquare(stagePos) - b.pos.distSquare(stagePos)
        
        return first p
        
    @setRect: (box, rect) ->
        
        r = first box.children()
        width = rect.x2 - rect.x
        height = rect.y2 - rect.y 
        r.size width, height
        t = last box.children()
        t.font 'size', height/2
        SnapBox.applyAnchor box
            
    @setAnchor: (box, anchor) ->
        
        t = last box.children()
        t.font 'anchor', anchor
        t.data 'anchor', anchor
        SnapBox.applyAnchor box
        
    @applyAnchor: (box) ->
        
        r = first box.children()
        t = last box.children()
        width  = r.width()
        height = r.height()
        switch t.data 'anchor'
            when 'start'  then t.transform x:Math.min(height/2, width/10), y:0 #t.x Math.min height/2, width/10
            when 'middle' then t.transform x:width/2, y:0
            when 'end'    then t.transform x:(width - Math.min(height/2, width/10)), y:0
            
    @resize: (box) -> SnapBox.applyAnchor box
            
    @svgElem: (kali, root) ->
             
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
        SnapBox.applyAnchor g
        t.style
            'stroke-opacity':   0        
            'fill-opacity':     tools.stroke.alpha
            fill:               tools.stroke.color
        g

module.exports = SnapBox

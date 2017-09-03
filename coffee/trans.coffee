
# 000000000  00000000    0000000   000   000   0000000
#    000     000   000  000   000  0000  000  000     
#    000     0000000    000000000  000 0 000  0000000 
#    000     000   000  000   000  000  0000       000
#    000     000   000  000   000  000   000  0000000 

{ pos, log, _ } = require 'kxk'

{ normRect, rectWidth, rectHeight, rectCenter, rectOffset } = require './utils'

class Trans

    constructor: (@kali) ->

    center:    (item, c) -> if c? then @setCenter(item, c) else @getCenter item
    width:     (item, w) -> if w? then @setWidth( item, w) else @getWidth  item
    height:    (item, h) -> if h? then @setHeight(item, h) else @getHeight item
    size:      (item, s) -> if s? then @setSize(  item, s) else @getSize   item
    pos:       (item, p) -> if p? then @setPos(   item, p) else @getPos    item
    
    setCenter: (item, c) -> @setPos item, c.minus @getSize(item).scale 0.5
    getCenter: (item)    -> 

        tx = item.transform 'x'
        ty = item.transform 'y'
        
        switch item.type
            
            when 'circle', 'ellipse' then pos tx, ty
            else
                bb = item.bbox()
                pos(tx, ty).plus pos bb.cx, bb.cy
    
    setRect: (item, r) ->
        
        r = normRect r
        
        return if rectWidth(r) == 0 or rectHeight(r) == 0

        @setWidth  item, rectWidth  r 
        @setHeight item, rectHeight r 
        @setPos    item, rectOffset r
    
    setPos: (item, c) -> 
        
        bb = item.bbox()
    
        switch item.type
            when 'circle', 'ellipse'
                item.transform x:c.x+bb.width/2, y:c.y+bb.height/2
            else
                item.transform x:c.x-bb.x, y:c.y-bb.y
        
    getPos: (item) -> 
    
        tx = item.transform 'x'
        ty = item.transform 'y'
        bb = item.bbox()
    
        switch item.type
            when 'circle', 'ellipse'
                pos tx-bb.width/2, ty-bb.height/2
            else
                pos tx+bb.x, ty+bb.y

    setWidth:  (item, w) -> 
    
        switch item.type
            
            when 'ellipse' then item.attr rx: w/2 
            when 'circle'  then item.attr r: w/2
            else                item.width w
    
    setHeight: (item, h) -> 
        
        switch item.type
            
            when 'ellipse' then item.attr ry: h/2 
            when 'circle'  then item.attr r: h/2
            else                item.height h
        
    setSize:   (item, s) -> @setWidth(item,s.x); @setHeight(item,s.y)
            
    getWidth:  (item) -> item.bbox().width
    getHeight: (item) -> item.bbox().height
    getSize:   (item) -> pos @width(item), @height(item)
    
module.exports = Trans

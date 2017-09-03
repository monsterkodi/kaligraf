
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
    size:      (item, s) -> if s? then @setSize(  item, s) else @getSize item
    
    getCenter: (item) ->
        switch item.type
            when 'ellipse', 'circle' then @getPos item
            else @getPos(item).plus @getSize(item).scale 0.5
            
    setCenter: (item, c) ->
        switch item.type
            when 'ellipse', 'circle' then @setPos item, c
            else @setPos item, c.minus @getSize(item).scale 0.5
    
    setRect: (item, r) ->
        r = normRect r

        switch item.type
            when 'ellipse'
                item.attr 
                    rx: rectWidth(r)/2
                    ry: rectHeight(r)/2
                    
                @setPos item, rectCenter r
            when 'circle'
                item.attr
                    r: Math.max rectWidth(r)/2, rectHeight(r)/2
                    
                @setPos item, rectCenter r
            else
                item.width  rectWidth  r
                item.height rectHeight r
        
                @setPos item, rectOffset r
    
    setPos: (item, c) -> 
        
        if item.type == 'text'
            p = pos(c).minus @getPos item
            item.transform {x:p.x, y:p.y}, true
        else
            item.transform x:c.x, y:c.y
        c
        
    getPos: (item) -> 
    
        if item.type == 'text'
            pos item.transform('x')+item.bbox().cx, item.transform('y')+item.bbox().cy
        else
            pos item.transform('x'), item.transform('y')

    setWidth:  (item, w) -> if item.type != 'text' then item.width(w)  else item.width(w)
    setHeight: (item, h) -> if item.type != 'text' then item.height(h) else item.height(h)
    setSize:   (item, s) -> @setWidth(item,s.x); @setHeight(item,s.y)
            
    getWidth:  (item) -> if item.type != 'text' then item.width()  else item.bbox().width
    getHeight: (item) -> if item.type != 'text' then item.height() else item.bbox().height
    getSize:   (item) -> pos @width(item), @height(item)
    
module.exports = Trans

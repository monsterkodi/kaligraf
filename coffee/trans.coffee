
# 000000000  00000000    0000000   000   000   0000000
#    000     000   000  000   000  0000  000  000     
#    000     0000000    000000000  000 0 000  0000000 
#    000     000   000  000   000  000  0000       000
#    000     000   000  000   000  000   000  0000000 

{ pos, log, _ } = require 'kxk'

{ normRect, rectWidth, rectHeight, rectCenter } = require './utils'

class Trans

    constructor: (@kali) ->

    center:    (item, c) -> if c? then @setCenter(item, c) else @getCenter item
    width:     (item, w) -> if w? then @setWidth( item, w) else @getWidth  item
    height:    (item, h) -> if h? then @setHeight(item, h) else @getHeight item
    
    setRect: (item, r) ->
        r = normRect r
        log 'setRect', r
        item.width  rectWidth  r
        item.height rectHeight r
        @setCenter item, pos r.x,r.y
    
    setCenter: (item, c) -> 
        
        if item.type == 'text'
            p = pos(c).minus @getCenter item
            item.transform {x:p.x, y:p.y}, true
        else
            item.transform x:c.x, y:c.y
        c
        
    getCenter: (item) -> 
    
        if item.type == 'text'
            pos item.transform('x')+item.bbox().cx, item.transform('y')+item.bbox().cy
        else
            pos item.transform('x'), item.transform('y')

    setWidth:  (item, w) -> if item.type != 'text' then item.width(w)  else item.width(w)
    setHeight: (item, h) -> if item.type != 'text' then item.height(h) else item.height(h)
            
    getWidth:  (item) -> if item.type != 'text' then item.width()  else item.bbox().width
    getHeight: (item) -> if item.type != 'text' then item.height() else item.bbox().height
    
    size: (item) -> pos @width(item), @height(item)
    
module.exports = Trans

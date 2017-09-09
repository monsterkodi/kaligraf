
# 000000000  00000000    0000000   000   000   0000000
#    000     000   000  000   000  0000  000  000     
#    000     0000000    000000000  000 0 000  0000000 
#    000     000   000  000   000  000  0000       000
#    000     000   000  000   000  000   000  0000000 

{ pos, log, _ } = require 'kxk'

{ normRect, boxCenter, boxOffset, rectWidth, rectHeight, rectCenter, rectOffset } = require './utils'

class Trans

    constructor: (@kali) ->

    dot:    (a,b) -> a.x*b.x+a.y*b.y
    center: (item, c) -> if c? then @setCenter(item, c) else @getCenter item
    width:  (item, w) -> if w? then @setWidth( item, w) else @getWidth  item
    height: (item, h) -> if h? then @setHeight(item, h) else @getHeight item
    size:   (item, s) -> if s? then @setSize(  item, s) else @getSize   item
    pos:    (item, p) -> if p? then @setPos(   item, p) else @getPos    item
    rect:   (item, r) -> if r? then @setRect(  item, r) else @getRect   item
    rotation: (item, a, c) -> if a? then @setRotation(item, a, c) else @getRotation item

    transform: (item, p) -> pos new SVG.Point(p).transform item.transform().matrix
    inverse:   (item, p) -> pos new SVG.Point(p).transform item.transform().matrix.inverse()
    
    getRotation: (item) -> item.transform 'rotation'
    setRotation: (item, a, c) -> 
        if c?
            item.transform rotation:a, cx:c.x, cy:c.y
        else
            item.transform rotation:a
    
    resize: (item, matrix, scale) ->
        
        oldCenter = @getCenter item
        newCenter = new SVG.Point oldCenter
        newCenter = pos newCenter.transform matrix

        rotMat    = new SVG.Matrix().rotate item.transform().rotation
        oldSize   = @getSize item
        newSize1  = new SVG.Point oldSize
        newSize1  = newSize1.transform rotMat
        oldSize.y = -oldSize.y
        newSize2  = new SVG.Point oldSize
        newSize2  = newSize2.transform rotMat
        scaleDir  = scale.minus pos 1,1
        if Math.abs(@dot newSize1, scaleDir) > Math.abs(@dot newSize2, scaleDir)
            newSize = newSize1
        else
            newSize = newSize2
        newSize = newSize.transform new SVG.Matrix().scale scale.x, scale.y
        newSize = newSize.transform new SVG.Matrix().rotate -item.transform().rotation
        newSize = pos Math.abs(newSize.x), Math.abs(newSize.y)

        @setSize   item, newSize
        @setCenter item, newCenter
        
    setRect: (item, r) ->
         
        r = normRect   r
        w = rectWidth  r 
        h = rectHeight r
         
        return if w == 0 or h == 0

        @setWidth  item, w
        @setHeight item, h
         
        @setCenter item, rectCenter r
        
    getRect: (item) ->
        
        item.bbox().transform item.transform().matrix
    
    setCenter: (item, c) -> 
    
        switch item.type
            when 'circle', 'ellipse'
                item.transform x:c.x, y:c.y
            else
                bb = item.bbox().transform new SVG.Matrix().rotate @rotation item
                item.transform x:c.x-bb.cx, y:c.y-bb.cy
        
    getCenter: (item)    -> 
    
        @transform item, boxCenter item.bbox()
        
    setPos: (item, c) -> 
        
        bb = item.bbox()
    
        switch item.type
            when 'circle', 'ellipse'
                item.transform x:c.x+bb.width/2, y:c.y+bb.height/2
            else
                item.transform x:c.x-bb.x, y:c.y-bb.y
        
    getPos: (item) -> 
    
        @transform item, boxOffset item.bbox()
        
    setWidth:  (item, w) -> 
    
        switch item.type
            when 'text'    then item.font 'size', item.font('size')*w/@getWidth(item)
            when 'ellipse' then item.attr rx: w/2 
            when 'circle'  then item.attr r: w/2
            when 'rect'    then item.attr width: w
            else                item.width w
    
    setHeight: (item, h) -> 

        switch item.type
             
            when 'text'    then item.font 'size', item.font('size')*h/@getHeight(item)
            when 'ellipse' then item.attr ry: h/2 
            when 'circle'  then item.attr r: h/2
            when 'rect'    then item.attr height: h
            else                item.height h
        
    setSize:   (item, s) -> @setWidth(item,s.x); @setHeight(item,s.y)
            
    getWidth:  (item) -> item.bbox().width
    getHeight: (item) -> item.bbox().height
    getSize:   (item) -> pos @getWidth(item), @getHeight(item)
    
module.exports = Trans

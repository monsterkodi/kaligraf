###
000000000  00000000    0000000   000   000   0000000
   000     000   000  000   000  0000  000  000     
   000     0000000    000000000  000 0 000  0000000 
   000     000   000  000   000  000  0000       000
   000     000   000  000   000  000   000  0000000 
###

{ pos, log, _ } = require 'kxk'

{ normRect, boxCenter, boxOffset, boxPos, rectWidth, rectHeight, rectCenter, rectOffset, itemMatrix, itemBox } = require './utils'

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
    scale:    (item, s, c) -> if s? then @setScale(   item, s, c) else @getScale    item

    @fullTransform: (item, p) -> pos new SVG.Point(p).transform itemMatrix(item)
    fullTransform: (item, p) -> Trans.fullTransform item, p
    fullInverse:   (item, p) -> pos new SVG.Point(p).transform itemMatrix(item).inverse()

    transform: (item, p) -> pos new SVG.Point(p).transform item.transform().matrix
    inverse:   (item, p) -> pos new SVG.Point(p).transform item.transform().matrix.inverse()
    
    itemPosToView: (item, p) -> 
        pos new SVG.Point(p).transform itemMatrix item
                    
    follow: (follower, followee) ->
        follower.transform new SVG.Matrix()
        for ancestor in _.clone(followee.parents())
            follower.transform ancestor.transform(), relative:true
        follower.transform followee.transform(), relative:true
    
    getScale: (item) -> pos item.transform('scaleX'), item.transform('scaleY')
    setScale: (item, s, c) ->
        if c?
            item.transform scaleX:s.x, cx:c.x, cy:c.y
            item.transform scaleY:s.y, cx:c.x, cy:c.y
        else
            item.transform scaleX:s.x
            item.transform scaleY:s.y
    
    getRotation: (item) -> item.transform 'rotation'
    setRotation: (item, a, c) -> 
        if c?
            item.transform rotation:a, cx:c.x, cy:c.y
        else
            item.transform rotation:a
    
    # 00000000   00000000   0000000  000  0000000  00000000  
    # 000   000  000       000       000     000   000       
    # 0000000    0000000   0000000   000    000    0000000   
    # 000   000  000            000  000   000     000       
    # 000   000  00000000  0000000   000  0000000  00000000  
    
    newCenter: (item, matrix, scale) ->
        
        newCenter = new SVG.Point @getCenter item
        newCenter = pos newCenter.transform matrix
        
    newSize: (item, matrix, scale) ->
        
        itemTrans = item.transform()
        
        rotMat    = new SVG.Matrix().rotate itemTrans.rotation
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
        newSize = newSize.transform new SVG.Matrix().rotate -itemTrans.rotation
        newSize = pos Math.abs(newSize.x), Math.abs(newSize.y)
        
    resize: (item, matrix, scale) ->

        newCenter = @newCenter item, matrix, scale
        newSize   = @newSize   item, matrix, scale

        @setSize   item, newSize
        @setCenter item, newCenter
        
    #  0000000   00000000    0000000   000   000  00000000   
    # 000        000   000  000   000  000   000  000   000  
    # 000  0000  0000000    000   000  000   000  00000000   
    # 000   000  000   000  000   000  000   000  000        
    #  0000000   000   000   0000000    0000000   000        
    
    setGroupSize: (group, size) ->

        oldSize = @size group
        
        scale = pos size.x/oldSize.x, size.y/oldSize.y
        
        transmat = new SVG.Matrix().around 0, 0, new SVG.Matrix().scale scale.x, scale.y
        
        for item in group.children()
            
            @resize item, transmat, scale
            
        if 'snapbox' == group.data 'type'
            SnapBox = require './edit/snapbox'
            SnapBox.resize group
                  
    setGroupWidth:  (group, w) -> @setGroupSize group, x:w, y:@height(group)
    setGroupHeight: (group, h) -> @setGroupSize group, x:@width(group), y:h
    
    # 00000000   00000000   0000000  000000000  
    # 000   000  000       000          000     
    # 0000000    0000000   000          000     
    # 000   000  000       000          000     
    # 000   000  00000000   0000000     000     
    
    setRect: (item, r) ->
         
        r = normRect   r
        w = rectWidth  r 
        h = rectHeight r
         
        return if w == 0 or h == 0

        @setWidth  item, w
        @setHeight item, h
         
        @setCenter item, rectCenter r
        
    getRect: (item) ->
        
        itemBox(item).transform itemMatrix item
    
    #  0000000  00000000  000   000  000000000  00000000  00000000   
    # 000       000       0000  000     000     000       000   000  
    # 000       0000000   000 0 000     000     0000000   0000000    
    # 000       000       000  0000     000     000       000   000  
    #  0000000  00000000  000   000     000     00000000  000   000  
    
    setCenter: (item, c) ->
    
        switch item.type
            when 'circle', 'ellipse'
                item.transform x:c.x, y:c.y
            when 'mask'
                bb = @getRect item
                delta = boxCenter(bb).to c
                delta = @fullInverse item, delta
                for child in item.children()
                    child.transform x:delta.x, y:delta.y, relative:true
            else
                scale = @scale item
                bb = itemBox(item).transform new SVG.Matrix().scale(scale.x, scale.y).rotate(@rotation item)
                item.transform x:c.x-bb.cx, y:c.y-bb.cy
        
    getCenter: (item) -> @transform item, boxCenter itemBox item
        
    # 00000000    0000000    0000000  
    # 000   000  000   000  000       
    # 00000000   000   000  0000000   
    # 000        000   000       000  
    # 000         0000000   0000000   
    
    setPos: (item, c) -> 
        
        bb = itemBox item
    
        switch item.type
            when 'circle', 'ellipse'
                item.transform x:c.x+bb.width/2, y:c.y+bb.height/2
            when 'mask'
                delta = boxPos(bb).to c
                for child in item.children()
                    child.transform x:delta.x, y:delta.y, relative:true                
            else
                item.transform x:c.x-bb.x, y:c.y-bb.y
                
    getPos: (item) -> @transform item, boxOffset itemBox item
       
    #  0000000  000  0000000  00000000    
    # 000       000     000   000         
    # 0000000   000    000    0000000     
    #      000  000   000     000         
    # 0000000   000  0000000  00000000    
        
    setWidth:  (item, w) -> 
    
        switch item.type
            when 'ellipse' then item.attr rx: w/2 
            when 'circle'  then item.attr r: w/2
            when 'rect'    then item.attr width: w
            when 'g'       then @setGroupWidth item, w
            when 'text'    
                if @getWidth(item) > 0 and w > 0
                    item.font 'size', item.font('size')*w/@getWidth(item)
            else
                item.width w
                
    setHeight: (item, h) -> 

        switch item.type
             
            when 'ellipse' then item.attr ry: h/2 
            when 'circle'  then item.attr r: h/2
            when 'rect'    then item.attr height: h
            when 'g'       then @setGroupHeight item, h
            when 'text'    
                if @getHeight(item) > 0 and h > 0
                    item.font 'size', item.font('size')*h/@getHeight(item)
            else
                item.height h
                
    setSize:   (item, size) -> 
    
        if item.type == 'g' 
            @setGroupSize item, size
        else
            @setWidth  item, size.x 
            @setHeight item, size.y 
            
    getWidth:  (item) -> item.bbox().width
    getHeight: (item) -> item.bbox().height
    getSize:   (item) -> pos @getWidth(item), @getHeight(item)
    
module.exports = Trans

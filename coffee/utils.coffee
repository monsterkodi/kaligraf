# 000   000  000000000  000  000       0000000    
# 000   000     000     000  000      000         
# 000   000     000     000  000      0000000     
# 000   000     000     000  000           000    
#  0000000      000     000  0000000  0000000     

{ empty, pos, log } = require 'kxk'

module.exports = 
    
    # 0000000     0000000   000   000  
    # 000   000  000   000   000 000   
    # 0000000    000   000    00000    
    # 000   000  000   000   000 000   
    # 0000000     0000000   000   000  
    
    boxForItems: (items, offset={x:0,y:0}) ->
        
        if empty items
            return new SVG.RBox() 
            
        bb = null
        for item in items
            b = item.rbox()
            bb ?= b
            bb = bb.merge b

        module.exports.moveBox bb, pos -offset.x, -offset.y

    boxCenter: (box) -> pos box.x + box.width/2.0, box.y + box.height/2.0
    boxOffset: (box) -> pos box.x, box.y
    zoomBox:  (box, zoom)  -> module.exports.scaleBox 1.0/zoom
    scaleBox: (box, scale) ->
        
        box.x      *= scale
        box.y      *= scale
        box.width  *= scale
        box.height *= scale
        
        if box.cx? then box.cx *= scale
        if box.x2? then box.x2 *= scale
        if box.cy? then box.cy *= scale
        if box.y2? then box.y2 *= scale
        
        if box.w? then box.w = box.width
        if box.h? then box.h = box.height
        
        box

    moveBox: (box, delta) -> 
        
        box.x += delta.x
        box.y += delta.y
        if box.cx? then box.cx += delta.x
        if box.x2? then box.x2 += delta.x
        if box.cy? then box.cy += delta.y
        if box.y2? then box.y2 += delta.y
        
        box        

    #  0000000   00000000    0000000   000   000  
    # 000        000   000  000   000  000 0 000  
    # 000  0000  0000000    000   000  000000000  
    # 000   000  000   000  000   000  000   000  
    #  0000000   000   000   0000000   00     00  
    
    growBox: (box, percent=10) ->

        w = box.width * percent / 100
        box.width = box.width + 2*w
        box.x -= w
        
        h = box.height * percent / 100
        box.height = box.height + 2*h
        box.y -= h
        
        if box.w?  then box.w  = box.width
        if box.h?  then box.h  = box.height
        if box.x2? then box.x2 = box.x + box.width
        if box.y2? then box.y2 = box.y + box.height
        if box.cx? then box.cx = box.x + box.w/2
        if box.cy? then box.cy = box.y + box.y/2
        
        box
        
    # 00000000   00000000   0000000  000000000  
    # 000   000  000       000          000     
    # 0000000    0000000   000          000     
    # 000   000  000       000          000     
    # 000   000  00000000   0000000     000     
    
    posForRect: (r) -> pos parseInt(r.x), parseInt(r.y)
        
    # 000  000   000  000000000  00000000  00000000    0000000  00000000   0000000  000000000  
    # 000  0000  000     000     000       000   000  000       000       000          000     
    # 000  000 0 000     000     0000000   0000000    0000000   0000000   000          000     
    # 000  000  0000     000     000       000   000       000  000       000          000     
    # 000  000   000     000     00000000  000   000  0000000   00000000   0000000     000     
    
    rectsIntersect: (a, b) ->
        
        if a.x2 < b.x then return false
        if a.y2 < b.y then return false
        if b.x2 < a.x then return false
        if b.y2 < a.y then return false
        true
        
    # 000   000   0000000   00000000   00     00  
    # 0000  000  000   000  000   000  000   000  
    # 000 0 000  000   000  0000000    000000000  
    # 000  0000  000   000  000   000  000 0 000  
    # 000   000   0000000   000   000  000   000  
    
    normRect: (r) ->
        
        [sx, ex] = [r.x, r.x2]
        [sy, ey] = [r.y, r.y2]
        if sx > ex then [sx, ex] = [ex, sx]
        if sy > ey then [sy, ey] = [ey, sy] 
        x:sx, y:sy, x2:ex, y2:ey
    
    
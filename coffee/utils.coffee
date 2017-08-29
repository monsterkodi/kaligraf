# 000   000  000000000  000  000       0000000    
# 000   000     000     000  000      000         
# 000   000     000     000  000      0000000     
# 000   000     000     000  000           000    
#  0000000      000     000  0000000  0000000     

{ empty, pos } = require 'kxk'

module.exports = 
    
    boxForItems: (items, offset={x:0,y:0}) ->
        return new SVG.RBox() if empty items
        bb = null
        for item in items
            bb ?= item.rbox()
            bb = bb.merge item.rbox()
        bb.transform new SVG.Matrix().translate -offset.x, -offset.y

    moveBox: (box, d) -> box.x += d.x; box.y += d.y; box
        
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
        
    # 000   000   0000000   00000000   00     00  00000000   00000000   0000000  000000000  
    # 0000  000  000   000  000   000  000   000  000   000  000       000          000     
    # 000 0 000  000   000  0000000    000000000  0000000    0000000   000          000     
    # 000  0000  000   000  000   000  000 0 000  000   000  000       000          000     
    # 000   000   0000000   000   000  000   000  000   000  00000000   0000000     000     
    
    normRect: (r) ->
        
        [sx, ex] = [r.x, r.x2]
        [sy, ey] = [r.y, r.y2]
        if sx > ex then [sx, ex] = [ex, sx]
        if sy > ey then [sy, ey] = [ey, sy] 
        x:sx, y:sy, x2:ex, y2:ey
    
    #  0000000   00000000    0000000   000   000  
    # 000        000   000  000   000  000 0 000  
    # 000  0000  0000000    000   000  000000000  
    # 000   000  000   000  000   000  000   000  
    #  0000000   000   000   0000000   00     00  
    
    growViewBox: (box, percent=10) ->

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
        
        if box.zoom? then box.zoom *= (100-2*percent)/100
        box
    
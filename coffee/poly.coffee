
# 00000000    0000000   000      000   000  
# 000   000  000   000  000       000 000   
# 00000000   000   000  000        00000    
# 000        000   000  000         000     
# 000         0000000   0000000     000     

{ last, pos, log, _ } = require 'kxk'

Draw = require './draw'

class Poly extends Draw
                        
    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    handleDown: (event, stagePos) ->
        
        if not @drawing? then return false
        
        switch @shape
            when 'polygon', 'polyline'  then @addPoint      stagePos
            when 'line'                 then @setLastPoint  stagePos
            
        true
        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    handleDrag: (event, stagePos) ->
        
        if not @drawing? then return false
        
        switch @shape
            when 'polygon', 'polyline'  then @addPoint      stagePos
            when 'line'                 then @setLastPoint  stagePos 
            
        true
        
    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
    addPoint: (p) ->
        
        points = @points()
        tail = points.length > 1 and points[points.length-2] or points[points.length-1]
        dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
        if points.length < 2 or dist > 20
            @append [p.x, p.y]
        else
            @set -1, [p.x, p.y]

    setLastPoint: (p) -> @set -1, [p.x, p.y]
                
    removeLastPoint: ->
        
        if @points().length > 2
            super

    pos: (l) -> pos l[0], l[1]
            
    continuePicking: -> @shape != 'line'

    handlePick: (stagePos) -> @picking = @drawing?
        
                    
module.exports = Poly
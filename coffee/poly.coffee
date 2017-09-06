
# 00000000    0000000   000      000   000  
# 000   000  000   000  000       000 000   
# 00000000   000   000  000        00000    
# 000        000   000  000         000     
# 000         0000000   0000000     000     

{ last, log, _ } = require 'kxk'

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
        tail = arr.length > 1 and arr[arr.length-2] or arr[arr.length-1]
        dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
        if arr.length < 2 or dist > 20
            arr.push [p.x, p.y]
        else
            last(arr)[0] = p.x
            last(arr)[1] = p.y
        @plot()

    setLastPoint: (p) ->
        
        point = @lastPoint()
        point[0] = p.x
        point[1] = p.y
        @plot()
        
    removeLastPoint: ->
        
        points = @points()
        if points.length > 2
            points.pop() 
            @plot() 
                
    continuePicking: -> @shape != 'line'

    handlePick: (stagePos) -> @picking = @drawing?
        
                    
module.exports = Poly
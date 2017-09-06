
# 00000000    0000000   000      000   000  
# 000   000  000   000  000       000 000   
# 00000000   000   000  000        00000    
# 000        000   000  000         000     
# 000         0000000   0000000     000     

{ last, log, _ } = require 'kxk'

{ boxCenter } = require './utils'

class Poly 
    
    constructor: (@kali) ->
    
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    startDrawing: (@drawing, @shape, stagePos) -> delete @picking
                    
    handleDown: (event, stagePos) ->
        
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
        
        switch @shape
            when 'polygon', 'polyline'  then @addPoint      stagePos
            when 'line'                 then @setLastPoint  stagePos 
        true
        
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    handleMove: (event, stagePos) ->
                
        if @drawing? and @picking

            @setLastPoint stagePos
            
        true

    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    handleStop: (event, stagePos) ->
        
        if @drawing?
            
            if @picking
                return false

            c = boxCenter @drawing.bbox()
            @drawing.center 0, 0
            @kali.trans.center @drawing, c
            
        true

    endDrawing: -> 
    
        delete @drawing
        delete @picking

    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
    addPoint: (p) ->
        
        arr  = @drawing.array().valueOf()
        tail = arr.length > 1 and arr[arr.length-2] or arr[arr.length-1]
        dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
        if arr.length < 2 or dist > 20
            arr.push [p.x, p.y]
        else
            last(arr)[0] = p.x
            last(arr)[1] = p.y
        @drawing.plot arr

    setLastPoint: (p) ->
        
        arr = @drawing.array().valueOf()
        last(arr)[0] = p.x
        last(arr)[1] = p.y
        @drawing.plot arr
        
    removeLastPoint: ->
        
        arr = @drawing.array().valueOf()
        arr.pop() if arr.length > 2
        @drawing.plot arr        
        
    handleEscape: ->
        
        if @drawing then @removeLastPoint()
        
    continuePicking: -> @shape != 'line'

    handlePick: (stagePos) -> @picking = @drawing?
        
                    
module.exports = Poly
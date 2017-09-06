
# 00000000    0000000   000      000   000  
# 000   000  000   000  000       000 000   
# 00000000   000   000  000        00000    
# 000        000   000  000         000     
# 000         0000000   0000000     000     

{ last, log, _ } = require 'kxk'

{ boxCenter } = require './utils'

class Poly 
    
    constructor: (@kali) ->
    
    startDrawing: (@drawing, @shape, stagePos) ->
                    
    handleDown: (event, stagePos) ->
        
        switch @shape
            when 'polygon', 'polyline'  then @addPolyPoint stagePos
            when 'line'                 then @setLinePoint stagePos
        true
        
    handleMove: (event, stagePos) ->
        
        switch @shape
            when 'polygon', 'polyline'  then @addPolyPoint stagePos
            when 'line'                 then @setLinePoint stagePos 
        true
        
    handleStageMove: (stagePos) ->
                
        if @drawing? and @drawing.remember 'isPickPoly'

            @setLinePoint stagePos
            
        true

    handleStop: (event, stagePos) ->
        
        if @drawing?
            
            if @drawing.remember 'isPickPoly'
                return false

            c = boxCenter @drawing.bbox()
            @drawing.center 0, 0
            @kali.trans.center @drawing, c
            
        true

    continuePicking: -> @shape != 'line'

    handlePick: (stagePos) ->
        
        @drawing?.remember 'isPickPoly', true
        true
    
    endDrawing: -> delete @drawing
            
    setLinePoint: (p) ->
        
        arr = @drawing.array().valueOf()
        last(arr)[0] = p.x
        last(arr)[1] = p.y
        @drawing.plot arr
        
    addPolyPoint: (p) ->
        
        arr  = @drawing.array().valueOf()
        tail = arr.length > 1 and arr[arr.length-2] or arr[arr.length-1]
        dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
        if arr.length < 2 or dist > 20
            arr.push [p.x, p.y]
        else
            last(arr)[0] = p.x
            last(arr)[1] = p.y
        @drawing.plot arr

    updatePolyPoint: (p) ->
        
        arr = @drawing.array().valueOf()
        last(arr)[0] = p.x
        last(arr)[1] = p.y
        @drawing.plot arr
        
    removeLastPolyPoint: ->
        
        arr = @drawing.array().valueOf()
        arr.pop() if arr.length > 2
        @drawing.plot arr        
        
    handleEscape: ->
        
        if @drawing then @removeLastPolyPoint()
        
module.exports = Poly
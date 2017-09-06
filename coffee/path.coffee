
# 00000000    0000000   000000000  000   000  
# 000   000  000   000     000     000   000  
# 00000000   000000000     000     000000000  
# 000        000   000     000     000   000  
# 000        000   000     000     000   000  

{ last, log, _ } = require 'kxk'

{ boxCenter } = require './utils'

class Path
    
    constructor: (@kali) ->
    
    startDrawing: (@drawing, @shape, stagePos) ->
                    
    handleDown: (event, stagePos) ->
        log "Path.handleDown stagePos:", stagePos
        
        switch @shape
            when 'bezier', 'bezier_quad'  then @addPoint stagePos
            # when 'line'                 then @setLinePoint stagePos
        true
        
    handleMove: (event, stagePos) ->
        log "Path.handleMove stagePos:", stagePos

        switch @shape
            when 'pie', 'arc' then return false
        
        # switch @shape
            # when 'bezier', 'bezier_quad'  then @addPoint stagePos
            # when 'line'                 then @setLinePoint stagePos 
        true
        
    handleStageMove: (stagePos) ->
        log "Path.handleStageMove stagePos:", stagePos
                
        if @drawing? and @drawing.remember 'isPickPath'

            @setLastPoint stagePos
            
        true

    handleStop: (event, stagePos) ->
        log "Path.handleStop stagePos:", stagePos
        
        # if @drawing?
#             
            # if @drawing.remember 'isPickPath'
                # return false

            # c = boxCenter @drawing.bbox()
            # @drawing.center 0, 0
            # @kali.trans.center @drawing, c
            
        true

    addPoint: (p) ->
        
        arr = @drawing.array()
        a = arr.valueOf()
        a.push ['L', p.x, p.y]
        @drawing.plot arr
        
    setLastPoint: (p) ->
        
        arr = @drawing.array()
        e = last arr.valueOf()
        l = e.length
        e[l-2] = p.x
        e[l-1] = p.y
        @drawing.plot arr
        
    removeLastPoint: ->
        
        arr = @drawing.array()
        a = arr.valueOf()
        a.pop()
        @drawing.plot arr        
        
    continuePicking: -> true

    handlePick: (stagePos) ->
        log "Path.handlePick stagePos:", stagePos
        
        switch @shape
            when 'pie', 'arc' then return false
            
        @drawing?.remember 'isPickPath', true
        
        true
    
    endDrawing: -> 
        
        log "Path.endDrawing"
        delete @drawing
            
    handleEscape: ->
        
        if @drawing then @removeLastPoint()
        
module.exports = Path

# 00000000    0000000   000      000   000  
# 000   000  000   000  000       000 000   
# 00000000   000   000  000        00000    
# 000        000   000  000         000     
# 000         0000000   0000000     000     

{ boxCenter } = require './utils'

class Path
    
    constructor: (@kali) ->
    
    startDrawing: (@drawing, @shape, stagePos) ->
                    
    handleDown: (drag, event, stagePos) ->
        
        # switch @shape
            # when 'polygon', 'polyline'  then @addPolyPoint stagePos
            # when 'line'                 then @setLinePoint stagePos
        true
        
    handleMove: (drag, event, stagePos) ->
        
        # switch @shape
            # when 'polygon', 'polyline'  then @addPolyPoint stagePos
            # when 'line'                 then @setLinePoint stagePos 
        true
        
    handleStageMove: (stagePos) ->
                
        # if @drawing? and @drawing.remember 'isPickPath'

            # @setLinePoint stagePos
            
        true

    handleStop: (drag, event, stagePos) ->
        
        # if @drawing?
#             
            # if @drawing.remember 'isPickPath'
                # return false

            # c = boxCenter @drawing.bbox()
            # @drawing.center 0, 0
            # @kali.trans.center @drawing, c
            
        true

    continuePicking: -> true

    handlePick: (stagePos) ->
        
        @drawing?.remember 'isPickPath', true
        true
    
    endDrawing: -> delete @drawing
            
    handleEscape: ->
        
module.exports = Path
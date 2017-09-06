
# 0000000    00000000    0000000   000   000
# 000   000  000   000  000   000  000 0 000
# 000   000  0000000    000000000  000000000
# 000   000  000   000  000   000  000   000
# 0000000    000   000  000   000  00     00

{ last, log, _ } = require 'kxk'
{ boxCenter } = require './utils'

class Draw

    constructor: (@kali) -> 

    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    startDrawing: (@drawing, @shape, stagePos) -> delete @picking

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
            
            if @picking then return false

            # c = boxCenter @drawing.bbox()
            # @drawing.center 0, 0
            # @kali.trans.center @drawing, c
            
        true

    handleEscape: ->
        
        if @drawing then @removeLastPoint()
        
    # 00000000  000   000  0000000    
    # 000       0000  000  000   000  
    # 0000000   000 0 000  000   000  
    # 000       000  0000  000   000  
    # 00000000  000   000  0000000    
    
    endDrawing: -> 
    
        delete @drawing
        delete @picking

    continuePicking: -> @picking
    
    points:    -> @drawing.array().valueOf()
    lastPoint: -> last @points()

    removeLastPoint: ->
        @points().pop() 
        @plot() 
    
    plot: -> @drawing.plot @drawing.array()
    
    append: (l) -> 
        @points().push l
        @plot()
        
    set: (i, l) ->
        @points().splice i, 1, l
        @plot()

module.exports = Draw

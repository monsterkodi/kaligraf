
# 0000000    00000000    0000000   000   000
# 000   000  000   000  000   000  000 0 000
# 000   000  0000000    000000000  000000000
# 000   000  000   000  000   000  000   000
# 0000000    000   000  000   000  00     00

{ post, first, last, log, _ } = require 'kxk'
{ boxCenter } = require './utils'

Edit = require './edit'

class Draw

    constructor: (@kali) ->
    
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    startDrawing: (@drawing, @shape, stagePos) -> 
    
        delete @picking
        @edit = new Edit @kali
        @edit.dotSize = 5
        
        switch @shape 
            when 'arc', 'pie' then
            else
                @edit.addItem @drawing

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
        @edit?.del()
        delete @edit
        delete @drawing
        delete @picking

    continuePicking: -> @picking
    
    plot: (points=@drawing.array()) -> @drawing.plot points
    points:    -> @drawing.array().valueOf()
    lastPoint: -> last @points()
    firstPoint: -> first @points()
    index: (i) -> if i < 0 then i + @points().length else i
    posAt: (i) -> if p = @pointAt i then @pos p
    pointAt: (i) -> 
        points = @points()
        i = @index i;
        if i < points.length then points[i]
        else 
            log "wrong index? #{i}/#{points.length}"
            null

    removeLastPoint: ->
        index = @index -1
        post.emit 'ctrl', @drawing, 'delete', 'point', index, @posAt(index), @pointAt(index)
        @points().pop() 
        @plot()
    
    append: (l) ->
        @points().push l
        index = @index -1
        post.emit 'ctrl', @drawing, 'append', 'point', index, @posAt(index), @pointAt(index)
        @plot()
        
    set: (i, l) ->
        index = @index i 
        points = @points()
        points.splice i, 1, l
        @plot points
        post.emit 'ctrl', @drawing, 'change', 'point', index, @posAt(index), @pointAt(index)
    
module.exports = Draw

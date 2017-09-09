
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
    
        @kali.stage.shapes.stopEdit()
        
        delete @picking
        @edit = new Edit @kali, true
        
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

            @moveLastPoint stagePos
            
        true

    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    handleStop: (event, stagePos) ->
        
        not (@drawing? and @picking)
            
    handleEscape: -> if @drawing then @removeLastPoint()
        
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
    posAt: (i) -> if p = @pointAt(i) then @pos p
    pointAt: (i) -> 
        points = @points()
        i = @index i;
        if i < points.length then points[i]
        else 
            log "wrong index? #{i}/#{points.length}"
            null

    removeLastPoint: -> @delete -1
    moveLastPoint: (p) -> @setLastPoint p
    setLastPoint:  (p) -> @setPoint -1, p
        
    setPoint: (i, p) ->
        index = @index -1
        points = @points()
        point = points[index]
        @setPos point, p
        @plot points
        post.emit 'ctrl', @drawing, 'change', 'point', index, @posAt(index)
    
    delete: (i) ->
        index = @index i
        points = @points()
        post.emit 'ctrl', @drawing, 'delete', 'point', index, @posAt(index)
        _.pull points, points[index]
        @plot points
        
    append: (l) ->
        points = @points()
        points.push l
        @plot points
        index = @index -1
        if l[0] != 'Z'
            post.emit 'ctrl', @drawing, 'append', 'point', index, @posAt(index)
        
    change: (i, l) ->
        index = @index i 
        points = @points()
        points.splice i, 1, l
        @plot points
        post.emit 'ctrl', @drawing, 'change', 'point', index, @posAt(index)
    
module.exports = Draw


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
        
        switch @shape 
            when 'arc', 'pie' then
            else
                for i in [0...@points().length]
                    post.emit 'draw', @, 'append', i

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
    
    posAt: (i) ->
        points = @points()
        i = @index i
        if i < points.length
            @pos points[i]
        else
            log "wrong index? #{i}/#{points.length}"
            null

    removeLastPoint: ->
        post.emit 'draw', @, 'delete', @index -1
        @points().pop() 
        @plot()
    
    append: (l) ->
        @points().push l
        post.emit 'draw', @, 'append', @index -1
        @plot()
        
    set: (i, l) ->
        points = @points()
        points.splice i, 1, l
        @plot points
        post.emit 'draw', @, 'change', @index i
    
module.exports = Draw

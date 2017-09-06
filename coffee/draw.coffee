
# 0000000    00000000    0000000   000   000
# 000   000  000   000  000   000  000 0 000
# 000   000  0000000    000000000  000000000
# 000   000  000   000  000   000  000   000
# 0000000    000   000  000   000  00     00

{ post, last, log, _ } = require 'kxk'
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
        
        if not @shape in ['arc', 'pie']
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
    
    points:    -> @drawing.array().valueOf()
    lastPoint: -> last @points()
    index: (i) -> if i < 0 then i + @points().length else i
    
    posAt: (i) ->
        points = @points()
        i = @index i
        if i < points.length
            # log "#{i}", points[i]
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
        @points().splice i, 1, l
        post.emit 'draw', @, 'change', @index i
        @plot()

    plot: -> @drawing.plot @drawing.array()
    
    
module.exports = Draw


# 00000000    0000000   000000000  000   000  
# 000   000  000   000     000     000   000  
# 00000000   000000000     000     000000000  
# 000        000   000     000     000   000  
# 000        000   000     000     000   000  

{ last, post, pos, log, _ } = require 'kxk'

{ boxCenter } = require './utils'

Draw = require './draw'

class Path extends Draw
        
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    startDrawing: (@drawing, @shape, stagePos) -> 
        
        super @drawing, @shape, stagePos
        
        switch @shape
            when 'pie', 'arc' 
                delete @command
            else 
                @command = @shape == 'bezier' and 'S' or 'Q'
                @picking = true
                    
    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    handleDown: (event, stagePos) ->

        if not @drawing? then return false
        
        switch @shape
            when 'pie', 'arc' then return false
            when 'bezier', 'bezier_quad' then @addPoint stagePos
          
        true
        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    handleDrag: (event, stagePos) ->

        if not @drawing? then return false
        
        switch @shape
            when 'pie', 'arc' then return false

        @setLastControlPoint stagePos
        
        true
        
    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
    addPoint: (p) -> @append ['L', p.x, p.y]
                
    setLastPoint: (p) ->
        
        point = @lastPoint()
        point[point.length-2] = p.x
        point[point.length-1] = p.y
        @plot()
        
    pos: (l) -> pos l[1], l[2]              
                
    #  0000000   0000000   000   000  000000000  00000000    0000000   000      
    # 000       000   000  0000  000     000     000   000  000   000  000      
    # 000       000   000  000 0 000     000     0000000    000   000  000      
    # 000       000   000  000  0000     000     000   000  000   000  000      
    #  0000000   0000000   000   000     000     000   000   0000000   0000000  
    
    setLastControlPoint: (p) ->
        
        points = @points()
        
        if points.length < 2
            switch @shape
                when 'bezier', 'bezier_quad' 
                    @append [@command, p.x, p.y, p.x, p.y]
                    post.emit 'ctrl', @, 'append', 'ctrl', @index(-1), p
                    return 
            
        point = last points
        switch point[0]
            when 'M', 'm', 'L', 'l' 
                @set -1, [@command, p.x, p.y, p.x, p.y]
                post.emit 'ctrl', @, 'append', 'ctrl', @index(-1), p
                
            when 'C', 'c', 'T', 't', 'S', 's', 'Q', 'q'
                point[1] = p.x
                point[2] = p.y
                @plot()
                post.emit 'ctrl', @, 'change', 'ctrl', @index(-1), p
        
    # 00000000   000   0000000  000   000
    # 000   000  000  000       000  000 
    # 00000000   000  000       0000000  
    # 000        000  000       000  000 
    # 000        000   0000000  000   000
    
    handlePick: (stagePos) ->
        
        switch @shape
            when 'pie', 'arc' then delete @picking
            else @picking = true            
        
        @picking

    handleEscape: ->
        
        if @drawing 
            switch @shape 
                when 'bezier', 'bezier_quad'
                    @setLastPoint @pos @firstPoint()
                else
                    super
        
module.exports = Path
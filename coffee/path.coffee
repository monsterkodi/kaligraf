
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

        @setLastPoint   stagePos
        @setLastControl stagePos
        
        true

    #  0000000   0000000   000   000  000000000  00000000    0000000   000      
    # 000       000   000  0000  000     000     000   000  000   000  000      
    # 000       000   000  000 0 000     000     0000000    000   000  000      
    # 000       000   000  000  0000     000     000   000  000   000  000      
    #  0000000   0000000   000   000     000     000   000   0000000   0000000  
    
    setLastControl: (p) ->
        index = @index -1
        points = @points()
        point = points[index]
        switch point[0]
                
            when 'Q', 'S'
                point[1] = p.x                
                point[2] = p.y
                @plot points
                post.emit 'ctrl', @drawing, 'change', 'ctrl1', index, p
                
    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
    addPoint: (p) -> 
        
        @append [@command, p.x, p.y, p.x, p.y]
        post.emit 'ctrl', @drawing, 'append', 'ctrl1', @index(-1), p
        if @command == 'S'
            post.emit 'ctrl', @drawing, 'append', 'ctrlr', @index(-1), p

    moveLastPoint: (p) ->
        super p
            
    closeLoop: ->
        
        @setLastPoint @pos @firstPoint()
        @append ['Z']
        
    pos: (point) -> 
        switch point[0]
            when 'S', 'Q' then pos point[3], point[4]
            else               pos point[1], point[2]
            
    setPos: (point, p) -> 
        switch point[0]
            when 'S', 'Q' then point[3] = p.x; point[4] = p.y
            else               point[1] = p.x; point[2] = p.y
                
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
        
        if @drawing?
            switch @shape 
                when 'bezier', 'bezier_quad'
                    @closeLoop()
                else
                    super
        
module.exports = Path
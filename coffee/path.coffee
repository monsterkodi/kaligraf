
# 00000000    0000000   000000000  000   000  
# 000   000  000   000     000     000   000  
# 00000000   000000000     000     000000000  
# 000        000   000     000     000   000  
# 000        000   000     000     000   000  

{ last, log, _ } = require 'kxk'

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
    
    addPoint: (p) ->
        
        @points().push ['L', p.x, p.y]
        @plot()
        
    setLastPoint: (p) ->
        
        point = @lastPoint()
        l = point.length
        point[l-2] = p.x
        point[l-1] = p.y
        @plot()
        
    removeLastPoint: ->
        
        @points().pop()
        @plot()
        
    #  0000000   0000000   000   000  000000000  00000000    0000000   000      
    # 000       000   000  0000  000     000     000   000  000   000  000      
    # 000       000   000  000 0 000     000     0000000    000   000  000      
    # 000       000   000  000  0000     000     000   000  000   000  000      
    #  0000000   0000000   000   000     000     000   000   0000000   0000000  
    
    setLastControlPoint: (p) ->
        
        arr = @drawing.array()
        a = arr.valueOf()
        if a.length < 2
            switch @shape
                when 'bezier', 'bezier_quad' then a.push [@command, p.x, p.y, p.x, p.y]
            
        e = last a
        l = e.length
        # log "control #{l}", e
        switch e[0]
            when 'M', 'm', 'L', 'l' 
                a.pop()
                a.push [@command, p.x, p.y, p.x, p.y]
            when 'C', 'c', 'T', 't', 'S', 's', 'Q', 'q'
                e[1] = p.x
                e[2] = p.y
            
        @drawing.plot arr
        
    # 00000000   000   0000000  000   000
    # 000   000  000  000       000  000 
    # 00000000   000  000       0000000  
    # 000        000  000       000  000 
    # 000        000   0000000  000   000
    
    continuePicking: -> @picking

    handlePick: (stagePos) ->
        log "Path.handlePick stagePos:", stagePos
        
        switch @shape
            when 'pie', 'arc' then delete @picking
            else @picking = true            
        
        @picking
                        
module.exports = Path
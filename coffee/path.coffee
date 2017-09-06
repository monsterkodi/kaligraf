
# 00000000    0000000   000000000  000   000  
# 000   000  000   000     000     000   000  
# 00000000   000000000     000     000000000  
# 000        000   000     000     000   000  
# 000        000   000     000     000   000  

{ last, log, _ } = require 'kxk'

{ boxCenter } = require './utils'

class Path
    
    constructor: (@kali) ->
    
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    startDrawing: (@drawing, @shape, stagePos) -> delete @picking
                    
    handleDown: (event, stagePos) ->
        log "Path.handleDown stagePos:", stagePos
        
        if not @drawing? then return false
        
        switch @shape
            when 'bezier', 'bezier_quad'  then @addPoint stagePos
            
        true
        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    handleDrag: (event, stagePos) ->
        log "Path.handleDrag stagePos:", stagePos

        if not @drawing? then return false
        
        switch @shape
            when 'pie', 'arc' then return false

        @setLastControlPoint stagePos
        true
        
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    handleMove: (event, stagePos) ->
                
        if @drawing? and @picking

            log "Path.handleMove updateLast stagePos:", stagePos
            @setLastPoint stagePos
            
        true

    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    handleStop: (event, stagePos) ->
        log "Path.handleStop stagePos:", stagePos
        
        if @drawing? and @picking
             
                return false

            # c = boxCenter @drawing.bbox()
            # @drawing.center 0, 0
            # @kali.trans.center @drawing, c
            
        true

    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
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

    handleEscape: ->
        
        if @drawing then @removeLastPoint()
        
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
                when 'bezier'      then a.push ['S', p.x, p.y, p.x, p.y]
                when 'bezier_quad' then a.push ['Q', p.x, p.y, p.x, p.y]
            
        e = last a
        l = e.length
        log "control #{l}", e
        switch e[0]
            when 'M', 'm' then log 'convert M'
            when 'L', 'l' then log 'convert L'
            when 'C', 'c' then log 'move C'
            when 'T', 't' then log 'move T'
            when 'S', 's' then log 'move S'; e[1] = p.x; e[2] = p.y;
            when 'Q', 'q' then log 'move Q'; e[1] = p.x; e[2] = p.y;
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
    
    # 00000000  000   000  0000000    
    # 000       0000  000  000   000  
    # 0000000   000 0 000  000   000  
    # 000       000  0000  000   000  
    # 00000000  000   000  0000000    
    
    endDrawing: -> 
        
        log "Path.endDrawing"
        delete @drawing
                    
module.exports = Path

# 0000000    00000000    0000000   000   000
# 000   000  000   000  000   000  000 0 000
# 000   000  0000000    000000000  000000000
# 000   000  000   000  000   000  000   000
# 0000000    000   000  000   000  00     00

{ post, first, last, pos, log, _ } = require 'kxk'

Edit = require './edit'

class Draw

    constructor: (@kali) ->
        
        @stage = @kali.stage
    
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    startDrawing: (@drawing, @shape) -> 
    
        @kali.stage.shapes.stopEdit()
        
        @edit = new Edit @kali, true
        
        switch @shape
            when 'arc', 'pie' then
            else
                @edit.addItem @drawing
                
        switch @shape
            when 'line', 'polyline', 'polygon'
                @picking = true
            else
                delete @picking

    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    handleDown: (event) ->

        if not @drawing? then return false

        viewPos = @stage.viewForEvent pos event
        
        switch @shape
            when 'pie', 'arc'            then return false
            when 'polygon', 'polyline'   then @addPoint  viewPos
            when 'bezier', 'bezier_quad' then @addPoint  viewPos
            when 'line'                  then @movePoint viewPos
            
        true
        
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    handleMove: (event) ->
                
        if @drawing? and @picking

            @movePoint @stage.viewForEvent pos event
            
        true

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    handleDrag: (event) ->
        
        if not @drawing? then return false
        
        viewPos = @stage.viewForEvent pos event
        
        switch @shape
            
            when 'pie', 'arc' then return false
            
            when 'polygon', 'polyline'  
                
                dist = viewPos.dist @pointPosAt @drawing.array().valueOf().length-2
                if dist < 10
                    @movePoint viewPos
                else
                    @addPoint  viewPos
            else
                @movePoint viewPos
            
        true

    # 00000000   000   0000000  000   000  
    # 000   000  000  000       000  000   
    # 00000000   000  000       0000000    
    # 000        000  000       000  000   
    # 000        000   0000000  000   000  
    
    handlePick: () ->
        
        switch @shape
            when 'pie', 'arc'          then delete @picking
            when 'bezier', 'bezier_quad' then @picking = true
            when 'line'                  then @picking = true
            else         
                @picking = @drawing?
                
        @picking
        
    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    handleStop: (event) -> 
        
        return true if @shape == 'line'
        not (@drawing? and @picking)
            
    # 00000000   0000000   0000000   0000000   00000000   00000000  
    # 000       000       000       000   000  000   000  000       
    # 0000000   0000000   000       000000000  00000000   0000000   
    # 000            000  000       000   000  000        000       
    # 00000000  0000000    0000000  000   000  000        00000000  
    
    handleEscape: -> 
        
        return if not @drawing?
        
        object = @edit.objectForItem @drawing
        
        if object.points().length <= 2 
            log 'delete?'
        
        switch @shape 
            when 'bezier', 'bezier_quad'
                @movePoint @pointPosAt 0
            else 
                object.delPoint object.ctrls.length-1

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

    continuePicking: -> @picking and @shape != 'line'

    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
    addPoint: (p) ->

        viewPos = @stage.viewForEvent pos event 
        object  = @edit.objectForItem @drawing
        types   = ['point']
        object.addPoint object.ctrls.length, viewPos, types
        object.plot()

    movePoint: (viewPos) ->
        
        object  = @edit.objectForItem @drawing
        types   = ['point']
        object.movePoint object.ctrls.length-1, viewPos, types
        object.plot()
       
    pointPosAt: (index) ->
        
        if pointDot = @edit.objectForItem(@drawing).ctrls[index]?.dots.point
            pos pointDot.cx(), pointDot.cy()
        else
            log "no point dot at index #{index}?"
        
module.exports = Draw


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
    
    del: -> @endDrawing()
        
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    startDrawing: (@drawing, @shape) -> 
    
        @stage.shapes.stopEdit()
        
        @edit ?= new Edit @kali, true
        @edit.clear()
        
        switch @shape
            when 'arc', 'pie' then
            else
                @edit.addItem @drawing
                
        switch @shape
            when 'line', 'polyline', 'polygon' then
            when 'bezier', 'bezier_quad', 'bezier_cube' 
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

        stagePos = @stage.stageForEvent pos event
        
        switch @shape
            when 'pie', 'arc'            then return false
            when 'line'                  then @movePoint stagePos
            when 'polygon', 'polyline', 'bezier', 'bezier_quad', 'bezier_cube'  
                @addPoint stagePos
            
        true
        
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    handleMove: (event) ->
             
        if @drawing? and @picking

            @movePoint @stage.stageForEvent(pos event), 'move'
            
        true

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    handleDrag: (event) ->
        
        if not @drawing? then return false
        
        stagePos = @stage.stageForEvent pos event
        
        switch @shape
            
            when 'pie', 'arc' then return false
            
            when 'polygon', 'polyline'  
                
                dist = stagePos.dist @dotPos @drawing.array().valueOf().length-2
                if dist < 10
                    @movePoint stagePos, 'drag'
                else
                    @addPoint  stagePos
            else
                @movePoint stagePos, 'drag'
            
        true

    # 00000000   000   0000000  000   000  
    # 000   000  000  000       000  000   
    # 00000000   000  000       0000000    
    # 000        000  000       000  000   
    # 000        000   0000000  000   000  
    
    handlePick: () ->
        
        switch @shape
            when 'pie', 'arc'            then delete @picking
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
        
        return true  if not @drawing?
        return true  if @shape == 'line'
        return false if @shape in ['bezier', 'bezier_quad', 'bezier_cube']
        return not @picking
            
    # 00000000   0000000   0000000   0000000   00000000   00000000  
    # 000       000       000       000   000  000   000  000       
    # 0000000   0000000   000       000000000  00000000   0000000   
    # 000            000  000       000   000  000        000       
    # 00000000  0000000    0000000  000   000  000        00000000  
    
    handleEscape: ->
        
        return false if not @drawing?
        
        object = @edit.objectForItem @drawing
        
        if object.points().length < 2 
            log 'delete?'
        
        switch @shape
            when 'bezier', 'bezier_quad', 'bezier_cube'
                @movePoint @dotPos 0
            else 
                object.delPoint object.ctrls.length-1
            
        true

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

        stagePos = @stage.stageForEvent pos event 
        object  = @edit.objectForItem @drawing
        code    = switch @shape
            when 'bezier'      then 'S'
            when 'bezier_quad' then 'Q'
            when 'bezier_cube' then 'C'
            else 'P'
        object.addPoint object.numPoints(), stagePos, code
        object.plot()

    movePoint: (stagePos, action) ->

        object = @edit.objectForItem @drawing
        if not object?
            log 'no object in edit?', @edit?, @drawing?
            return
        
        dots   = ['point']
        if action == 'drag'
            switch @shape
                when 'bezier'      then dots.push 'ctrls'
                when 'bezier_quad' then dots.push 'ctrlq'
                when 'bezier_cube' then dots.push 'ctrl1'; dots.push 'ctrl2'
        object.movePoint object.ctrls.length-1, stagePos, dots
        object.plot()
       
    dotPos: (index, dot='point') ->
        
        object = @edit.objectForItem(@drawing)
        object.dotPos index, dot       
        
module.exports = Draw
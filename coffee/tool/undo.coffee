
# 000   000  000   000  0000000     0000000   
# 000   000  0000  000  000   000  000   000  
# 000   000  000 0 000  000   000  000   000  
# 000   000  000  0000  000   000  000   000  
#  0000000   000   000  0000000     0000000   

{ post, log, _ } = require 'kxk'

Tool = require './tool'

class Undo extends Tool

    constructor: (kali, cfg) ->
        
        super kali, cfg
        
        @undo = @stage.undo
                        
        @initTitle()
        
        span = @initButtons [
            text:   '0'
            name:   'undos'
            action: @undo.undoAll
        ,
            text:   '0'
            name:   'redos'
            action: @undo.redoAll
        ]
        
        span.addEventListener 'wheel', @onSpinWheel
        
        span = @initButtons [
            button: true
            tiny:   'spin-minus'
            name:   'undo'
            action: @undo.undo
        ,
            button: true
            tiny:   'spin-plus'
            name:   'redo'
            action: @undo.redo
        ]
        
        span.addEventListener 'wheel', @onSpinWheel
        
        post.on 'undo', @onUndo
       
    # 000   000  000   000  00000000  00000000  000      
    # 000 0 000  000   000  000       000       000      
    # 000000000  000000000  0000000   0000000   000      
    # 000   000  000   000  000       000       000      
    # 00     00  000   000  00000000  00000000  0000000  
    
    onSpinWheel: (event) =>
        
        if Math.abs(event.deltaX) >= Math.abs(event.deltaY)
            delta = event.deltaX
        else
            delta = -event.deltaY
                
        @element.wheel ?= 0
        @element.wheel = @element.wheel + delta * 0.005

        while Math.abs(@element.wheel) >= 1
            if delta > 0
                @undo.redo()
                @element.wheel -= 1
            else
                @undo.undo()
                @element.wheel += 1
        
    onUndo: (info) => 
        
        @button('undos').innerHTML = info.undos
        @button('redos').innerHTML = info.redos
        
        @showButton 'undos', info.undos
        @showButton 'undo',  info.undos
            
        @showButton 'redos', info.redos
        @showButton 'redo',  info.redos
        
module.exports = Undo

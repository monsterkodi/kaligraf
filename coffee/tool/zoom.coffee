
# 0000000   0000000    0000000   00     00  
#    000   000   000  000   000  000   000  
#   000    000   000  000   000  000000000  
#  000     000   000  000   000  000 0 000  
# 0000000   0000000    0000000   000   000  

{ elem, post, log, _ } = require 'kxk'

Tool = require './tool'

class Zoom extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @stage = @kali.stage
                
        @initTitle 'Zoom'
        
        @initButtons [
            text:   'x1'
            name:   'reset'
            action: @reset
        ]
        @initButtons [
            text:   '-'
            name:   'out'
            action: @zoomOut
        ,
            text:   '+'
            name:   'in'
            action: @zoomIn
        ]
        
        post.on 'stage', @onStage
    
    # 000      00000000  000   000  00000000  000       0000000  
    # 000      000       000   000  000       000      000       
    # 000      0000000    000 000   0000000   000      0000000   
    # 000      000          000     000       000           000  
    # 0000000  00000000      0      00000000  0000000  0000000   
    
    @levels = [
        0.01, 0.02, 0.05,
        0.10, 0.15, 0.20, 0.25, 0.33, 0.50, 0.75,
        1, 1.5, 2, 3, 4, 5, 6, 8,
        10, 15, 20, 40, 80,
        100, 150, 200, 400, 800,
        1000
    ]
        
    # 000  000   000  
    # 000  0000  000  
    # 000  000 0 000  
    # 000  000  0000  
    # 000  000   000  
    
    zoomIn: (event) => 
        
        for i in [0...Zoom.levels.length]
            if @stage.zoom < Zoom.levels[i]
                @stage.setZoom Zoom.levels[i], @stage.stageCenter()
                return

    #  0000000   000   000  000000000  
    # 000   000  000   000     000     
    # 000   000  000   000     000     
    # 000   000  000   000     000     
    #  0000000    0000000      000     
    
    zoomOut: (event) =>
        
        for i in [Zoom.levels.length-1..0]
            if @stage.zoom > Zoom.levels[i]
                @stage.setZoom Zoom.levels[i], @stage.stageCenter()
                return

    # 00000000   00000000   0000000  00000000  000000000  
    # 000   000  000       000       000          000     
    # 0000000    0000000   0000000   0000000      000     
    # 000   000  000            000  000          000     
    # 000   000  00000000  0000000   00000000     000     
    
    reset: (event) => @stage.resetView()
                
    onStage: (action, value) =>
        
        switch action
            when 'zoom'
                btn = @button 'reset' 
                if value < 1
                    btn.innerHTML = "#{parseInt value*100}%"
                else if value < 1.1
                    btn.innerHTML = "x1"
                else if value < 2
                    btn.innerHTML = "x#{parseInt value}.#{parseInt(value*10) % 10}"
                else
                    btn.innerHTML = "x#{parseInt value}"
    
module.exports = Zoom


# 0000000   0000000    0000000   00     00  
#    000   000   000  000   000  000   000  
#   000    000   000  000   000  000000000  
#  000     000   000  000   000  000 0 000  
# 0000000   0000000    0000000   000   000  

{ stopEvent, elem, post, log, _ } = require 'kxk'

Tool = require './tool'

class Zoom extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @stage = @kali.stage
                
        @title = @element.appendChild elem 'div', class:'title', text: '100%'
        
        @minusPlus @zoomOut, @zoomIn
        
        post.on 'stage', @onStage
    
    @levels = [
        0.01, 0.02, 0.05,
        0.10, 0.15, 0.20, 0.25, 0.33, 0.50, 0.75,
        1, 1.5, 2, 3, 4, 5, 6, 8,
        10, 15, 20, 40, 80,
        100, 150, 200, 400, 800,
        1000
    ]
        
    zoomIn: (event) => 
        stopEvent event 
        
        for i in [0...Zoom.levels.length]
            if @stage.zoom < Zoom.levels[i]
                @stage.setZoom Zoom.levels[i], @stage.stageCenter()
                log Zoom.levels[i]
                return

    zoomOut: (event) =>
        stopEvent event 
        
        for i in [Zoom.levels.length-1..0]
            if @stage.zoom > Zoom.levels[i]
                @stage.setZoom Zoom.levels[i], @stage.stageCenter()
                log Zoom.levels[i]
                return
        
    onStage: (action, value) =>
        
        switch action
            when 'zoom'
                if value < 2
                    @title.innerHTML = "#{parseInt value*100}%"
                else
                    @title.innerHTML = "x#{parseInt value}"
    
module.exports = Zoom

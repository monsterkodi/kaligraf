
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
                
        @title = @element.appendChild elem 'div', class:'title', text: '100%'
        
        @minusPlus @onZoomOut, @onZoomIn
        
        post.on 'stage', @onStage
        
    onZoomIn:  (event) => stopEvent(event) and post.emit 'tool', 'zoom_in',  @name
    onZoomOut: (event) => stopEvent(event) and post.emit 'tool', 'zoom_out', @name
    
    onStage: (prop, value) =>
        
        switch prop
            when 'zoom'
                if value < 3
                    @title.innerHTML = "#{parseInt value*100}%"
                else
                    @title.innerHTML = "x#{parseInt value}"
    
module.exports = Zoom

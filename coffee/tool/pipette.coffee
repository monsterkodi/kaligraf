
# 00000000   000  00000000   00000000  000000000  000000000  00000000
# 000   000  000  000   000  000          000        000     000     
# 00000000   000  00000000   0000000      000        000     0000000 
# 000        000  000        000          000        000     000     
# 000        000  000        00000000     000        000     00000000

{ post, pos, log, $, _ } = require 'kxk'

Tool = require './tool' 
 
class Pipette extends Tool

    constructor: (@kali, cfg) ->

        super @kali, cfg
        
        @stage = @kali.stage
        @tools = @kali.tools

    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    onStageDown: (event) =>

        eventPos = pos event
        item = @stage.itemAtPos eventPos
        if item?
            
            @tools.fill.color = item.style 'fill' 
            @tools.fill.alpha = item.style 'fill-opacity' 
            @tools.fill.update()
            post.emit 'color', 'fill', 'color', @tools.fill.color
            
            @tools.stroke.color = item.style 'stroke' 
            @tools.stroke.alpha = item.style 'stroke-opacity' 
            @tools.stroke.update()
            post.emit 'color', 'stroke', 'color', @tools.stroke.color
            
            @tools.width.setWidth item.style 'stroke-width' 
            
            proxy = @tools[@kali.palette.proxy]
            @kali.palette.setClosestColor proxy.color, proxy.alpha

    onStageDrag: (drag, event) =>
        
        width = 100
        height = 100
        svg = '<rect width="50" height="40" style="fill: rgb(160, 0, 0);"></rect>'
        
        svgStr = btoa """
            <svg xmlns="http://www.w3.org/2000/svg" 
                 xmlns:xlink="http://www.w3.org/1999/xlink" 
                 version="1.1" 
                 width="#{width}px" 
                 height="#{height}px">#{svg}</svg>
        """
        
        @kali.stage.setCursor "url(data:image/svg+xml;base64,#{svgStr}) 18 12, auto"
        
    onStageStop: (drag, event) =>
        
        eventPos = pos event
        item = @stage.itemAtPos eventPos
        if item?
            log 'drop color at item?'
            
module.exports = Pipette

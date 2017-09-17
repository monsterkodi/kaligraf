
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

module.exports = Pipette

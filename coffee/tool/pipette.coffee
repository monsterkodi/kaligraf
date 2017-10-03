
# 00000000   000  00000000   00000000  000000000  000000000  00000000
# 000   000  000  000   000  000          000        000     000     
# 00000000   000  00000000   0000000      000        000     0000000 
# 000        000  000        000          000        000     000     
# 000        000  000        00000000     000        000     00000000

{ elem, post, pos, log, fs, fileExists, $, _ } = require 'kxk'

Exporter = require '../exporter'
Tool = require './tool' 
 
class Pipette extends Tool

    constructor: (@kali, cfg) ->

        super @kali, cfg
        
        @tools = @kali.tools

    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    onStageDown: (event) =>

        item = @stage.leafItemAtPos pos event

        if item?
            
            @tools.fill.color = item.style 'fill' 
            @tools.fill.alpha = item.style 'fill-opacity' 
            @tools.fill.update()
            
            @tools.stroke.color = item.style 'stroke' 
            @tools.stroke.alpha = item.style 'stroke-opacity' 
            @tools.stroke.update()
            
            @tools.width.setWidth item.style 'stroke-width' 
            
            proxy = @tools[@kali.palette.proxy]
            @kali.palette.setClosestColor proxy.color, proxy.alpha
            
            @kali.stage.setToolCursor 'pipette', fill: @tools.fill.color, stroke: @tools.stroke.color

    onStageDrag: (drag, event) =>
                
    onStageStop: (drag, event) =>
        
        @kali.stage.setToolCursor 'pipette'
        
        if drag.startPos == drag.lastPos
            post.emit 'color', 'fill',   prop:'color', color: @tools.fill.color, alpha: @tools.fill.alpha
            post.emit 'color', 'stroke', prop:'color', color: @tools.stroke.color, stroke: @tools.fill.alpha
            return
            
        item = @stage.leafItemAtPos pos event
        if item?
            @stage.undo.do @stage, 'color'+item.id()
            item.style 'fill',   @tools.fill.color
            item.style 'stroke', @tools.stroke.color
            @stage.undo.done @stage
            
module.exports = Pipette

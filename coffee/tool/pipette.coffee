
# 00000000   000  00000000   00000000  000000000  000000000  00000000
# 000   000  000  000   000  000          000        000     000     
# 00000000   000  00000000   0000000      000        000     0000000 
# 000        000  000        000          000        000     000     
# 000        000  000        00000000     000        000     00000000

{ elem, post, pos, log, fs, fileExists, $, _ } = require 'kxk'

Exporter = require '../exporter'
Tool     = require './tool' 
 
class Pipette extends Tool

    constructor: (kali, cfg) ->

        super kali, cfg
        
        @tools = @kali.tools

    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    onStageDown: (event) =>

        item = @stage.leafItemAtPos pos event

        if item?
                        
            @tools.fill.copyFromItems [item]
            @tools.stroke.copyFromItems [item]
            
            @tools.width.setWidth item.style 'stroke-width' 
            
            proxy = @tools[@kali.palette.proxy]
            @kali.palette.setClosestColor proxy.color, proxy.alpha
            
            @kali.stage.setToolCursor 'pipette', fill: @tools.fill.color, stroke: @tools.stroke.color

    onStageDrag: (drag, event) =>
                
    onStageStop: (drag, event) =>
        
        @kali.stage.setToolCursor 'pipette'
        
        doFill   = @tools.select.fillStroke.includes 'fill'
        doStroke = @tools.select.fillStroke.includes 'stroke'
        
        if drag.startPos == drag.lastPos
            if doFill
                post.emit 'color', 'fill',   prop:'color', color: @tools.fill.color,   alpha:  @tools.fill.alpha
            if doStroke
                post.emit 'color', 'stroke', prop:'color', color: @tools.stroke.color, stroke: @tools.fill.alpha
            return
            
        item = @stage.leafItemAtPos pos event
        if item?
            @stage.undo.do @stage, 'color'+item.id()
            style = {}
            if doFill
                style['fill']         = @tools.fill.color
                style['fill-opacity'] = @tools.fill.alpha
            if doStroke
                style['stroke']         = @tools.stroke.color
                style['stroke-opacity'] = @tools.stroke.alpha
                style['stroke-width']   = "#{@tools.width.width}px"
            item.style style
            @stage.undo.done @stage
            
module.exports = Pipette


# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 

{ elem, stopEvent, post, first, last, log, _
}    = require 'kxk'
Tool = require './tool'

class Tools extends Tool

    constructor: (@kali, cfg) ->
                
        super @kali, cfg
                
        @tools = @
        @children = []
        @setPos x:0, y:0
        
        post.on 'tool',   @onAction
        post.on 'toggle', (name) => @[name]?.toggleVisible()
        
        @kali.tools = @
        
        @init [
            { name: 'stroke',   class: 'color' }
            { name: 'fill',     class: 'color' }
            { name: 'pick',     group: 'shape' }
            [
                { name: 'polygon',  group: 'shape' }
                { name: 'polyline', group: 'shape' }
                { name: 'line',     group: 'shape' }
            ]
            [
                { name: 'rect',     group: 'shape' }
                { name: 'circle',   group: 'shape' }
                { name: 'ellipse',  group: 'shape' }
            ]
            [
                { name: 'zoom',     action: 'zoom_reset' }
                { name: '+',        action: 'zoom_in' }
                { name: '-',        action: 'zoom_out' }
                { name: 'dump',     action: 'dump' }
            ]
        ]
        
    # 000  000   000  000  000000000  
    # 000  0000  000  000     000     
    # 000  000 0 000  000     000     
    # 000  000  0000  000     000     
    # 000  000   000  000     000     
    
    init: (tools) ->
        
        for tool in tools
            @addTool tool
            
        @activateTool 'pick'
        @stroke.setLuminance 0.75
        @stroke.setAlpha 0.5
        @fill.setAlpha 0.7
        
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    addTool: (cfg) ->

        tool = @newTool cfg        
        
        tail = last @children
        tool.setPos x:0, y:(tail? and tail.pos().y or 0) + 60
        tool.parent = @
        @children.push tool
        tool.initChildren()
        tool

    newTool: (cfg) ->
        
        svgs =  
            rect:     '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs" viewBox="126.2 51.2 21.6 21.6"><rect id="SvgjsRect3272" width="18" height="18" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;" x="128" y="53"></rect></svg>'
            circle:   '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs" viewBox="158.2 91.2 21.6 21.6"><circle id="SvgjsCircle3350" r="9" cx="169" cy="102" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle></svg>'
            ellipse:  '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs" viewBox="90.42683639526368 74.40182952880859 13.735720825195312 27.471441650390624"><ellipse id="SvgjsEllipse3527" rx="5.7232175063123725" ry="11.446435012624745" cx="97.29469760731033" cy="88.13754959721054" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></ellipse></svg>'
            polygon:  '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs" viewBox="149.3 55.8 68.4 62.4"><polygon id="SvgjsPolygon1277" points="184,62 202,62 212,70 208,86 197,95 178,96 175,113 155,111 161,97 165,81 165,61" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></polygon></svg>'
            polyline: '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs" viewBox="205.2 86.5 33.6 54"><polyline id="SvgjsPolyline1144" points="208,92 227,91 236,100 232,116 213,117 212,136" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline></svg>'
            line:     '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs" viewBox="189.9 160.9 13.2 13.2"><line id="SvgjsLine1144" x1="191" y1="173" x2="202" y2="162" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></line></svg>'
                        
        if _.isArray cfg
            cfg[0].list = cfg.slice 1
            cfg = cfg[0]

        if svgs[cfg.name]?
            cfg.svg = svgs[cfg.name]
            
        clss = cfg.class and require("./#{cfg.class}") or Tool
        tool = new clss @kali, cfg
        @[tool.name] = tool
        tool
        
    #  0000000    0000000  000000000  000   0000000   000   000  
    # 000   000  000          000     000  000   000  0000  000  
    # 000000000  000          000     000  000   000  000 0 000  
    # 000   000  000          000     000  000   000  000  0000  
    # 000   000   0000000     000     000   0000000   000   000  
    
    onAction: (action, name) =>
        # log "Tools.onAction action:#{action} name:#{name}"
        
        switch action
            when 'activate'   then @activateTool name
            when 'dump'       then @kali.stage.dump()
            when 'zoom_reset' then @kali.stage.resetZoom()
            when 'zoom_in'    then @kali.stage.zoomIn()
            when 'zoom_out'   then @kali.stage.zoomOut()
            # else
                # log 'no action?', action, name
                    
    #  0000000    0000000  000000000  000  000   000   0000000   000000000  00000000  
    # 000   000  000          000     000  000   000  000   000     000     000       
    # 000000000  000          000     000   000 000   000000000     000     0000000   
    # 000   000  000          000     000     000     000   000     000     000       
    # 000   000   0000000     000     000      0      000   000     000     00000000  
    
    activateTool: (name) ->
        
        tool = @[name]
        if tool.group?
            active = @getActive tool.group
            active?.deactivate()
        tool.activate()
        
module.exports = Tools

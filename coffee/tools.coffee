
# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 

{ elem, stopEvent, post, last, log
}    = require 'kxk'
Tool = require './tool'

class Tools extends Tool

    constructor: (@kali, cfg) ->
                
        super @kali, cfg
        
        tools = [
            { name: 'stroke',   class: 'color' }
            { name: 'fill',     class: 'color' }
            { name: 'pick',     group: 'shape' }
            { name: 'polygon',  group: 'shape' }
            { name: 'polyline', group: 'shape' }
            { name: 'line',     group: 'shape' }
            { name: 'rect',     group: 'shape' }
            { name: 'circle',   group: 'shape' }
            { name: 'ellipse',  group: 'shape' }
            { name: 'pipette',                 }
            { name: 'dump',     action: 'dump' }
        ]
        
        @tools = @
        @children = [@]
        
        @setPos x:0, y:0
        
        for tool in tools
            @addTool tool
            
        post.on 'tool',   @onTool
        post.on 'toggle', (name) => @[name]?.toggleDisplay()
        
        @activateTool 'pick'
        @stroke.setLuminance 0.7
        @fill.setAlpha 0.7
        
    onTool: (action, name) =>
        
        switch action
            when 'activate' then @activateTool name
            when 'dump'     then @kali.stage.dump()
            else
                if name == @name
                    for c in @children
                        c.toggleDisplay() if c != @
                else
                    log 'no action?', action, name

    dragMove: (d,e) =>
        super d, e
        for c in @children
            c.moveBy d.delta
                    
    activateTool: (name) ->
        
        tool = @[name]
        if tool.group?
            active = @getActive tool.group
            active?.deactivate()
        tool.activate()
        
    getActive: (group) ->
        
        for tool in @children
            if tool.group == group and tool.active
                return tool
            
    addTool: (cfg) ->

        clss = cfg.class and require("./#{cfg.class}") or Tool
        tool = new clss @kali, cfg

        @[tool.name] = tool
        
        tail = last @children
        tool.setPos x:tail.pos().x, y:tail.pos().y+60
        
        @children.push tool
        
module.exports = Tools

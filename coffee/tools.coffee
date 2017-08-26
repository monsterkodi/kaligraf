
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
            name:  'pick'
            text:  'pick'
            group: 'shape'
        ,
            name:  'rect'
            text:  'rect'
            group: 'shape'
        ,
            name:  'circle'
            text:  'circle'
            group: 'shape'
        ,
            name:  'polygon'
            text:  'poly'
            group: 'shape'
        , 
            name:  'fill'
            class: 'color'
        , 
            name:  'stroke'
            class: 'color'
        ]
            
        @tools = []
        for tool in tools
            @addTool tool
            
        post.on 'tool', @onTool
        
        @activateTool 'rect'
        @stroke.setLuminance 0.7
        @fill.setAlpha 0.7
        
    onTool: (action, name) =>
        
        switch action
            when 'activate' then @activateTool name

    activateTool: (name) ->
        
        tool = @[name]
        if tool.group?
            active = @getActive tool.group
            active?.deactivate()
        tool.activate()
        
    getActive: (group) ->
        
        for tool in @tools
            if tool.group == group and tool.active
                return tool
            
    addTool: (cfg) ->

        clss = cfg.class and require("./#{cfg.class}") or Tool
        tool = new clss @kali, cfg

        tail = last @tools
        @tools.push tool
        @[tool.name] = tool
        
        if tail?
            tool.setPos x:tail.pos().x, y:tail.pos().y+60
        else
            tool.setPos x:0, y:60
        
module.exports = Tools

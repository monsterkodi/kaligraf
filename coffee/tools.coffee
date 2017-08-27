
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
            { name: 'dump',     action: 'dump' }
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
        @stroke.setLuminance 0.0
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
        
        if _.isArray cfg
            cfg[0].list = cfg.slice 1
            cfg = cfg[0]
        
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
            when 'activate' then @activateTool name
            when 'dump'     then @kali.stage.dump()
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

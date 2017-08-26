
# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 

{ elem, stopEvent, log
}    = require 'kxk'
Tool = require './tool'

class Tools extends Tool

    constructor: (parent) ->
                
        super name: 'tools', parent: parent
        
        @tools = []
        tools = [
            name: 'rect'
        ,
            name: 'circle'
        ,
            name: 'polygon'
        ]
            
        for tool in tools
            
            @addTool tool

    addTool: (tool) ->
        
        @tools.push new Tool name: tool.name, parent: @parent
                    
module.exports = Tools

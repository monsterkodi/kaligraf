
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
            rect:   '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs"><rect id="SvgjsRect1134" width="44" height="43" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;" x="7" y="7"></rect></svg>'
            circle: '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs"><circle id="SvgjsCircle1134" r="0" cx="82" cy="323" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1136" r="0" cx="244" cy="298" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1137" r="0" cx="197" cy="116" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1138" r="0" cx="242" cy="184" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1150" r="20" cx="30" cy="25" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle></svg>'
            ellipse: '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs"><circle id="SvgjsCircle1134" r="0" cx="82" cy="323" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1136" r="0" cx="244" cy="298" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1137" r="0" cx="197" cy="116" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1138" r="0" cx="242" cy="184" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1151" r="0" cx="39" cy="27" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1152" r="0" cx="265" cy="170" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><ellipse id="SvgjsEllipse1164" rx="12" ry="20" cx="28" cy="20" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;" transform="matrix(0.7071067811865481,0.7071067811865479,-0.7071067811865479,0.7071067811865481,23.3431457505076,-8.9411254969543)"></ellipse><ellipse id="SvgjsEllipse1165" rx="0" ry="0" cx="33" cy="17" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></ellipse></svg>'
            polygon: '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs"><circle id="SvgjsCircle1134" r="0" cx="82" cy="323" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1136" r="0" cx="244" cy="298" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1137" r="0" cx="197" cy="116" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1138" r="0" cx="242" cy="184" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1151" r="0" cx="39" cy="27" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1152" r="0" cx="265" cy="170" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><ellipse id="SvgjsEllipse1165" rx="0" ry="0" cx="33" cy="17" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></ellipse><polygon id="SvgjsPolygon1199" points="28,8 25,25 11,18 2,26 5,40 15,43 28,45 45,44 53,32 49,14 34,7" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></polygon></svg>'
            polyline: '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs"><circle id="SvgjsCircle1134" r="0" cx="82" cy="323" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1136" r="0" cx="244" cy="298" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1137" r="0" cx="197" cy="116" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1138" r="0" cx="242" cy="184" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1151" r="0" cx="39" cy="27" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1152" r="0" cx="265" cy="170" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><ellipse id="SvgjsEllipse1165" rx="0" ry="0" cx="33" cy="17" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></ellipse><polygon id="SvgjsPolygon1277" points="41,20" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></polygon><polyline id="SvgjsPolyline1397" points="25,19" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline><polyline id="SvgjsPolyline1414" points="23,5 41,5 52,12 48,27 35,28 18,24 20,44" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline><polyline id="SvgjsPolyline1450" points="23,25" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline><polyline id="SvgjsPolyline1453" points="21,40" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline><polyline id="SvgjsPolyline1456" points="45,25" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline></svg>'
            line: '<svg id="SvgjsSvg1001" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs"><circle id="SvgjsCircle1134" r="0" cx="82" cy="323" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1136" r="0" cx="244" cy="298" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1137" r="0" cx="197" cy="116" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1138" r="0" cx="242" cy="184" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1151" r="0" cx="39" cy="27" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><circle id="SvgjsCircle1152" r="0" cx="265" cy="170" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></circle><ellipse id="SvgjsEllipse1165" rx="0" ry="0" cx="33" cy="17" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></ellipse><polygon id="SvgjsPolygon1277" points="41,20" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: rgb(0, 0, 255); fill-opacity: 0.7;"></polygon><polyline id="SvgjsPolyline1397" points="25,19" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline><polyline id="SvgjsPolyline1450" points="23,25" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline><polyline id="SvgjsPolyline1453" points="21,40" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline><polyline id="SvgjsPolyline1456" points="45,25" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></polyline><line id="SvgjsLine1491" x1="8" y1="40" x2="47" y2="6" style="stroke: rgb(127, 127, 255); stroke-opacity: 0.5; fill: none; fill-opacity: 0;"></line></svg>'
                        
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

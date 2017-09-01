
# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 

{ elem, stopEvent, post, first, last, log, _ } = require 'kxk'

Tool = require './tool'

class Tools extends Tool

    constructor: (@kali, cfg) ->
                
        super @kali, cfg
                
        @tools    = []
        @children = []
        @setPos x:0, y:0
        
        post.on 'tool',   @onAction
        post.on 'toggle', (name) => @[name]?.toggleVisible()
        
        @kali.tools = @
                
    # 00000000   00000000   00000000  00000000   0000000  
    # 000   000  000   000  000       000       000       
    # 00000000   0000000    0000000   000000    0000000   
    # 000        000   000  000       000            000  
    # 000        000   000  00000000  000       0000000   
    
    loadPrefs: ->
        
        @stroke.setLuminance 1
        @stroke.setAlpha 0.5
        @fill.setLuminance 0
        @fill.setAlpha 0.15
        @width.setWidth 1
        
        @activateTool 'rect'
        @activateTool 'text'
        # @activateTool 'loupe'
        @activateTool 'pick'
        # @load.onClick()
    
    # 000  000   000  000  000000000  
    # 000  0000  000  000     000     
    # 000  000 0 000  000     000     
    # 000  000  0000  000     000     
    # 000  000   000  000     000     
    
    init: () ->

        tools = [
            [
                { name: 'zoom',  class: 'zoom', action: 'zoom_reset', combo: 'command+0' }
                { name: 'width', class: 'line' }
            ]
            { name: 'stroke', class: 'color' }
            { name: 'fill',   class: 'color' }
            [
                { name: 'pick',  group: 'shape' }
                { name: 'pan',   group: 'shape' }
                { name: 'loupe', group: 'shape' }
            ]
            [
                { name: 'rect',     group: 'shape' }
                { name: 'circle',   group: 'shape' }
                { name: 'ellipse',  group: 'shape' }
                { name: 'triangle', group: 'shape' }
            ]
            [
                { name: 'polygon',  group: 'shape' }
                { name: 'polyline', group: 'shape' }
                { name: 'line',     group: 'shape' }
            ]
            [
                { name: 'image',  group: 'shape'}
                { name: 'text',   group: 'shape'}
            ]
            [
                { name: 'save',  action: 'save',  orient: 'down', combo: 'command+s' }
                { name: 'load',  action: 'load',  orient: 'down', combo: 'command+o' }
                { name: 'clear', action: 'clear', orient: 'down', combo: 'command+k' }
            ]
            [
                { name: 'center', action: 'center',    orient: 'down', combo: 'command+e' }
                { name: 'all',    action: 'selectAll', orient: 'down', combo: 'command+a' }
                { name: 'none',   action: 'deselect',  orient: 'down', combo: 'command+d' }
            ]            
            [
                { name: 'cut',   action: 'cut',   orient: 'down', combo: 'command+x' }
                { name: 'copy',  action: 'copy',  orient: 'down', combo: 'command+c' }
                { name: 'paste', action: 'paste', orient: 'down', combo: 'command+v' }
            ]
            [
                { name: 'back',  action: 'back',  orient: 'down', combo: 'command+alt+down' }
                { name: 'lower', action: 'lower', orient: 'down', combo: 'command+down' }
                { name: 'raise', action: 'raise', orient: 'down', combo: 'command+up' }
                { name: 'front', action: 'front', orient: 'down', combo: 'command+alt+up' }
            ]            
        ]
        
        @element.style.zIndex = 1 
        for tool in tools
            @addTool tool
                    
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    addTool: (cfg) ->

        tool = @newTool cfg        

        tail = last @children
        
        if tool.cfg.orient == 'down'
            tool.setPos x:(tail? and tail.pos().x or 0) + 60, y:0
        else
            tool.setPos x:0, y:(tail? and tail.pos().y or -30) + 60
        
        tool.parent = @
        @children.push tool
        tool.initChildren()
        tool

    # 000   000  00000000  000   000  
    # 0000  000  000       000 0 000  
    # 000 0 000  0000000   000000000  
    # 000  0000  000       000   000  
    # 000   000  00000000  00     00  
    
    newTool: (cfg) ->
        
        svgs = 
            pick:     '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="782.1047241210938 207.43341674804688 130.932275390625 198.8575927734375"><rect id="SvgjsRect6038" width="51" height="90" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;" x="754" y="296" transform="matrix(0.8660254037844387,-0.49999999999999994,0.49999999999999994,0.8660254037844387,11.975480913295257,432.43371103399613)"></rect><polygon id="SvgjsPolygon6216" points="0,-50 82,3 0,50" transform="matrix(1,0,0,1,793.0157206632642,274.0048788265306)" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;"></polygon></svg>'
            pan:      '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="1128.69462890625 204.01193237304688 219.6 204"><polygon id="SvgjsPolygon7348" points="1228,291 1217,282 1208,275 1201,271 1186,264 1166,262 1158,272 1157,290 1162,299 1172,307 1181,312 1183,315 1194,322 1203,328 1212,336 1217,346 1224,351 1231,359 1240,362 1249,363 1265,365 1278,368 1292,369 1303,366 1313,359 1322,350 1329,342 1335,331 1339,317 1340,307 1340,294 1340,282 1340,272 1340,257 1339,249 1336,230 1332,217 1323,205 1313,200 1297,199 1280,199 1260,199 1247,205 1240,214 1235,227 1232,242 1229,259" transform="matrix(1,0,0,1,-10.005420918367347,22.011926020408165)" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;"></polygon></svg>'
            loupe:    '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="935.8024169921875 197.1119171142578 146.39736328125 190.78699951171876"><circle id="SvgjsCircle7199" r="48" cx="992" cy="241" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;" transform="matrix(1,0,0,1,4.002168367346939,20.010841836734695)"></circle><line id="SvgjsLine7211" x1="1070" y1="372" x2="1024" y2="305" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: none; fill-opacity: 0;"></line></svg>'
            rect:     '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="117.3 23.1 128.4 130.8"><rect id="SvgjsRect1667" width="107" height="109" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;" x="128" y="34"></rect></svg>'
            ellipse:  '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="415.6 23.4 52.8 133.2"><ellipse id="SvgjsEllipse1152" rx="22" ry="55.5" cx="446" cy="44" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;" transform="matrix(1,0,0,1,-4,46)"></ellipse></svg>'
            circle:   '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="260 22 132 132"><circle id="SvgjsCircle1415" r="55" cx="326" cy="89" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;" transform="matrix(1,0,0,1,0,-1)"></circle></svg>'
            polygon:  '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="1026.7 27.6 135.6 148.8"><polygon id="SvgjsPolygon5719" points="1045,40 1060,40 1077,40 1093,40 1109,40 1123,41 1137,45 1147,53 1151,67 1150,86 1142,97 1130,104 1115,108 1098,110 1079,110 1077,127 1077,145 1075,163 1038,164" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;"></polygon></svg>'
            polyline: '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="868.9 27 133.2 144"><polyline id="SvgjsPolyline4085" points="880,42 896,41 911,40 929,39 946,39 961,41 972,45 981,53 987,63 991,77 988,93 978,102 965,108 948,110 929,110 910,110 884,108 884,124 884,141 884,159" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: none; fill-opacity: 0;"></polyline></svg>'
            line:     '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="712.5 26.7 126 135.6"><line id="SvgjsLine2705" x1="723" y1="151" x2="828" y2="38" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: none; fill-opacity: 0;"></line></svg>'
            triangle: '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" viewBox="553.068017578125 22.470184326171875 154.8 138"><polygon id="SvgjsPolygon2686" points="50,-63 112,52 -17,52" transform="matrix(1,0,0,1,582.968016581634,96.97018494897958)" style="stroke: rgb(127, 127, 255); stroke-opacity: 1; stroke-width: 10; fill: rgb(50, 50, 255); fill-opacity: 0.5;"></polygon></svg>'
                        
        if _.isArray cfg
            cfg[0].list = cfg.slice 1
            cfg = cfg[0]

        if svgs[cfg.name]?
            cfg.svg = svgs[cfg.name]
            
        clss = cfg.class and require("./#{cfg.class}") or Tool
        tool = new clss @kali, cfg
        @[tool.name] = tool
        @tools.push tool
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
            when 'cut'        then @kali.stage.cut()
            when 'copy'       then @kali.stage.copy()
            when 'paste'      then @kali.stage.paste()
            when 'save'       then @kali.stage.save()
            when 'clear'      then @kali.stage.clear()
            when 'load'       then @kali.stage.load()
            when 'zoom_reset' then @kali.stage.resetView()
            when 'zoom_in'    then @kali.stage.zoomIn()
            when 'zoom_out'   then @kali.stage.zoomOut()
            when 'lower'      then @kali.stage.order 'backward'
            when 'raise'      then @kali.stage.order 'forward'
            when 'back'       then @kali.stage.order 'back'
            when 'front'      then @kali.stage.order 'front'
            when 'selectAll'  then @kali.stage.select 'all'
            when 'deselect'   then @kali.stage.select 'none'
            when 'center'     then @kali.stage.centerSelection()
            
            else
                log 'action?', action, name

    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event, down) ->
        # log "Tools.handleKey mod:#{mod} key:#{key} combo:#{combo} down:#{down}"

        if down 
            if mod == 'ctrl' then @ctrlDown = true
            
            for tool in @tools
                if tool.cfg.combo == combo
                    return tool.onClick()
            
        else
            @ctrlDown = false
            
        if @kali.shapeTool() == 'loupe'
            @kali.stage.svg.style cursor:@ctrlDown and 'zoom-out' or 'zoom-in'
            
        'unhandled'
                
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
        
        cursor = switch name
            when 'pan'      then '-webkit-grab'
            when 'loupe'    then @ctrlDown and 'zoom-out' or 'zoom-in'
            else 'default'
        
        @kali.stage.resizer.activate name == 'pick'
            
        @kali.stage.svg.style cursor: cursor

    collapseTemp: ->
        
        if @temp 
            @temp.hideChildren()
            delete @temp
        
module.exports = Tools


# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 

{ elem, stopEvent, fileExists, post, first, last, empty, fs, path, log, _ } = require 'kxk'

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
        
        @stroke.set 
            mode:  'gry'
            value: 0.2
            alpha: 0.9
            
        @fill.set 
            mode:  'gry'
            value: 0.1
            # luminance: 0.2
            alpha: 0.5
            
        @width.setWidth 4
        
        @grid.showGrid()
        
        @activateTool 'rect'
        @activateTool 'text'
        @activateTool 'pick'
        @activateTool 'bezier'
        @activateTool 'edit'
        
        post.emit 'stage', 'setColor', '#666'
        post.emit 'tool', 'load'
        
    # 000  000   000  000  000000000  
    # 000  0000  000  000     000     
    # 000  000 0 000  000     000     
    # 000  000  0000  000     000     
    # 000  000   000  000     000     
    
    init: () ->

        @stage = @kali.stage
        
        tools = [
            [
                { name: 'stroke', class: 'color' }
                { name: 'fill',   class: 'color' }
            ]
            [
                { name: 'pick',    group: 'shape' }
                { name: 'edit',    group: 'shape' }
                { name: 'pan',     group: 'shape' }
                { name: 'loupe',   group: 'shape' }
                { name: 'pipette', group: 'shape' }
            ]
            [
                { name: 'rect',     group: 'shape' }
                { name: 'circle',   group: 'shape' }
                { name: 'ellipse',  group: 'shape' }
                { name: 'triangle', group: 'shape' }
                { name: 'triangle_square', group: 'shape' }
            ]
            [
                { name: 'bezier',      group: 'shape', draw: true }
                { name: 'bezier_quad', group: 'shape', draw: true }
                { name: 'bezier_cube', group: 'shape', draw: true }
                { name: 'pie',         group: 'shape', draw: true }
                { name: 'arc',         group: 'shape', draw: true }
            ]
            [
                { name: 'polygon',     group: 'shape', draw: true }
                { name: 'polyline',    group: 'shape', draw: true }
                { name: 'line',        group: 'shape', draw: true }
            ]
            [
                { name: 'zoom',  class: 'zoom', action: 'zoom_reset',  combo: 'command+0' }
                { name: 'grid',  class: 'grid', action: 'grid_toggle', combo: 'command+g' }
                { name: 'width', class: 'line' }
            ]            
            [
                { name: 'image',  group: 'shape'}
                { name: 'text',   group: 'shape'}
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
                                
        if _.isArray cfg
            cfg[0].list = cfg.slice 1
            cfg = cfg[0]
            
        if cfg.svg = @loadSVG cfg.name
            
        else if cfg.group == 'shape'
            
            cfg.svg = @loadSVG 'rect'
            
        clss = cfg.class and require("./#{cfg.class}") or Tool
        tool = new clss @kali, cfg
        @[tool.name] = tool
        @tools.push tool
        tool
        
    loadSVG: (name) ->
        svgFile = "#{__dirname}/../svg/#{name}.svg"
        if fileExists svgFile
            return fs.readFileSync svgFile, encoding: 'utf8'

    saveSVG: (name, svg) ->
        svgFile = "#{__dirname}/../svg/#{name}.svg"
        fs.writeFileSync svgFile, svg, encoding: 'utf8'
            
    #  0000000    0000000  000000000  000   0000000   000   000  
    # 000   000  000          000     000  000   000  0000  000  
    # 000000000  000          000     000  000   000  000 0 000  
    # 000   000  000          000     000  000   000  000  0000  
    # 000   000   0000000     000     000   0000000   000   000  
    
    onAction: (action, name) =>
        
        switch action
            when 'activate'   then @activateTool name
            when 'cut'        then @stage.cut()
            when 'copy'       then @stage.copy()
            when 'paste'      then @stage.paste()
            when 'save'       then @stage.save()
            when 'clear'      then @stage.clear()
            when 'load'       then @stage.load()
            when 'zoom_reset' then @stage.resetView()
            when 'zoom_in'    then @stage.zoomIn()
            when 'zoom_out'   then @stage.zoomOut()
            when 'lower'      then @stage.order  'backward'
            when 'raise'      then @stage.order  'forward'
            when 'back'       then @stage.order  'back'
            when 'front'      then @stage.order  'front'
            when 'selectAll'  then @stage.select 'all'
            when 'deselect'   then @stage.select 'none'
            when 'center'     then @stage.centerSelection()
            when 'grid_toggle' then @grid.toggleGrid()

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
            @stage.setCursor @ctrlDown and 'zoom-out' or 'zoom-in'
            
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
        
        switch name
            when 'edit'
                if not @stage.selection.empty() 
                    @stage.swapSelection()
            when 'pick' 
                if @stage.shapes.edit? and not @stage.shapes.edit.empty()
                    @stage.swapSelection()
        
        cursor = switch name
            when 'pan'      then '-webkit-grab'
            when 'loupe'    then @ctrlDown and 'zoom-out' or 'zoom-in'
            when 'pipette'  then 'alias'
            else 'default'
        
        @stage.resizer.activate name == 'pick'
            
        @stage.setCursor cursor
        
    collapseTemp: ->
        
        if @temp 
            @temp.hideChildren()
            delete @temp
        
module.exports = Tools

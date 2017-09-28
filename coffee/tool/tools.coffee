
# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 

{ elem, stopEvent, post, prefs, first, last, empty, fs, path, log, _ } = require 'kxk'

Exporter = require '../exporter'
Tool     = require './tool'

class Tools extends Tool

    constructor: (@kali, cfg) ->
                
        super @kali, cfg
                
        @element.style.zIndex = 9999
        
        @tools    = []
        @children = []
        @setPos x:0, y:0
        
        @kali.toolDiv.addEventListener 'mouseleave', @collapseTemp
        
        post.on 'tool',   @onAction
        post.on 'toggle', (name) => @[name]?.toggleVisible()
        
    #  0000000    0000000  000000000  000   0000000   000   000  
    # 000   000  000          000     000  000   000  0000  000  
    # 000000000  000          000     000  000   000  000 0 000  
    # 000   000  000          000     000  000   000  000  0000  
    # 000   000   0000000     000     000   0000000   000   000  
    
    onAction: (action, tool, button) =>
        
        # log "tools.onAction #{action} #{tool} #{button}"
        
        switch action
            
            when 'click'      then @clickTool        tool
            when 'button'     then @clickToolButton  tool, button
            when 'activate'   then @activateTool     tool
            when 'browse'     then @kali.openBrowser()
            when 'group'      then @stage.group()
            when 'ungroup'    then @stage.ungroup()
            when 'cut'        then @stage.cut()
            when 'copy'       then @stage.copy()
            when 'paste'      then @stage.paste()
            when 'undo'       then @stage.undo.undo()
            when 'redo'       then @stage.undo.redo()
            when 'new'        then @stage.new()
            when 'open'       then @stage.open()
            when 'load'       then @stage.load()
            when 'save'       then @stage.save()
            when 'saveAs'     then @stage.saveAs()
            when 'import'     then @stage.import()
            when 'export'     then @stage.export()
            when 'clear'      then @stage.doClear()
            when 'selectAll'  then @stage.shapes.select 'all'
            when 'deselect'   then @stage.shapes.select 'none'
            when 'invert'     then @stage.shapes.select 'invert'
            when 'center'     then @stage.centerSelection()
            when 'swapColor'  then @stroke.swapColor()
            else log "unhandled tool action #{action} #{tool}"
        
    # 000  000   000  000  000000000  
    # 000  0000  000  000     000     
    # 000  000 0 000  000     000     
    # 000  000  0000  000     000     
    # 000  000   000  000     000     
    
    init: () ->

        @stage     = @kali.stage
        @shapes    = @stage.shapes
        @selection = @stage.selection
        
        tools = [
            [
                { name: 'stroke', class: 'color' }
                { name: 'fill',   class: 'color' }
            ]
            [
                { name: 'pick',     group: 'shape' }
                { name: 'edit',     group: 'shape' }
                { name: 'pan',      group: 'shape' }
                { class: 'loupe',   group: 'shape' }
                { class: 'pipette', group: 'shape' }
            ]
            [
                { name: 'rect',     group: 'shape' }
                { name: 'triangle', group: 'shape' }
                { name: 'triangle_square', group: 'shape' }
                { name: 'image',    group: 'shape' }
            ]
            [
                { name: 'circle',   group: 'shape' }
                { name: 'ellipse',  group: 'shape' }
            ]
            [
                { name: 'bezier_smooth', group: 'shape', draw: true }
                { name: 'bezier_quad',   group: 'shape', draw: true }
                { name: 'bezier_cube',   group: 'shape', draw: true }
                { name: 'pie',           group: 'shape', draw: true }
                { name: 'arc',           group: 'shape', draw: true }
            ]
            [
                { name: 'polygon',  group: 'shape', draw: true }
                { name: 'polyline', group: 'shape', draw: true }
                { name: 'line',     group: 'shape', draw: true }
            ]
            [
                { name:  'text',    group: 'shape' }
                { class: 'font'  }
            ]
            [
                { class: 'angle' }
                { class: 'undo'  }
                { class: 'line', name: 'width' }
            ]
            [
                { class: 'group' }
                { class: 'order' }
                { class: 'send'  }
                { class: 'space' }                
                { class: 'align' }                
            ]            
            [
                { class: 'zoom'  }
                { class: 'layer' }
                { class: 'grid'  }
                { class: 'show'  }
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
            tool.setPos x:(tail? and tail.pos().x or 0) + @kali.toolSize, y:0
        else
            tool.setPos x:0, y:(tail? and tail.pos().y or 0) + @kali.toolSize
        
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
            
        if cfg.svg = Exporter.loadSVG cfg.name ? cfg.class
            
            if 'group' == (cfg.name ? cfg.class)
                delete cfg.svg 
            
        else if cfg.group == 'shape'
            
            cfg.svg = Exporter.loadSVG 'rect'
            
        clss = cfg.class and require("./#{cfg.class}") or Tool
        tool = new clss @kali, cfg
        @[tool.name] = tool
        @tools.push tool
        tool
        
    # 00000000   00000000   00000000  00000000   0000000  
    # 000   000  000   000  000       000       000       
    # 00000000   0000000    0000000   000000    0000000   
    # 000        000   000  000       000            000  
    # 000        000   000  00000000  000       0000000   
    
    loadPrefs: ->
        
        @clickTool prefs.get 'activeTool', 'pick' 
        @clickTool 'font'  if prefs.get 'fontlist:visible', false
        @clickTool 'layer' if prefs.get 'layerlist:visible', false
        
        if recent = first prefs.get 'recent', []
            @stage.load recent
            
        if box = prefs.get 'stage:viewbox'
            @stage.zoom = box.zoom
            @stage.setViewBox box
            
        if prefs.get 'browser:open', false
            setImmediate => @kali.openBrowser()
                    
    collapseTemp: =>

        if @temp 
            @temp.hideChildren()
            delete @temp
        
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event, down) ->

        if down
            if mod == 'ctrl' then @ctrlDown = true
            
            for tool in @tools
                if tool.cfg.combo == combo
                    return tool.onClick()
            
        else
            @ctrlDown = false
            
        if @kali.shapeTool() == 'loupe'
            @stage.setToolCursor @ctrlDown and 'zoom-out' or 'zoom-in'
            
        'unhandled'

    clickTool: (tool) => @getTool(tool)?.onClick()
    clickToolButton: (tool, button) =>  
        @getTool(tool)?.clickButton button
        
    #  0000000    0000000  000000000  000  000   000   0000000   000000000  00000000  
    # 000   000  000          000     000  000   000  000   000     000     000       
    # 000000000  000          000     000   000 000   000000000     000     0000000   
    # 000   000  000          000     000     000     000   000     000     000       
    # 000   000   0000000     000     000      0      000   000     000     00000000  
    
    activateTool: (name) ->
        
        if name == 'tools'
            tool = @
        else
            tool = @[name]
                
        if tool.group?
            active = @getActive tool.group
            active?.deactivate()
            
        tool.activate()
        
        prefs.set 'activeTool', name
        
        if name == 'text'
            @selection.clear()
        else
            if name not in ['edit', 'pan', 'loupe']
                @shapes.stopEdit()
            @shapes.clearText()
        
        switch name
            when 'edit'
                if not @selection.empty() 
                    @shapes.editItems @stage.selectedLeafItems()
                    @selection.clear()
            when 'pick' 
                if @shapes.edit? and not @shapes.edit.empty()
                    @selection.setItems @shapes.edit?.items()
                    @shapes.stopEdit()
                
        @stage.resizer.activate name == 'pick'
            
        @stage.setToolCursor name
                
module.exports = Tools


# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 

{ elem, stopEvent, post, prefs, first, last, empty, fs, path, pos, log, _ } = require 'kxk'

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
            when 'font'       then @getTool('font').toggleList()
            when 'layer'      then @getTool('layer').toggleList()
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
                { name: 'stroke', class: 'color', popup: 'auto' }
                { name: 'fill',   class: 'color' }
            ]
            [
                { name: 'pick',     group: 'shape', popup: 'temp' }
                { name: 'edit',     group: 'shape', popup: 'temp' }
                { name: 'pan',      group: 'shape', popup: 'temp' }
                { class: 'loupe',   group: 'shape', popup: 'temp' }
                { class: 'pipette', group: 'shape', popup: 'temp' }
            ]
            [
                { name: 'bezier_smooth', draw: true, group: 'shape', popup: 'temp' }
                { name: 'bezier_quad',   draw: true, group: 'shape', popup: 'temp' }
                { name: 'bezier_cube',   draw: true, group: 'shape', popup: 'temp' }
                { name: 'polygon',       draw: true, group: 'shape', popup: 'temp' }
                { name: 'polyline',      draw: true, group: 'shape', popup: 'temp' }
                { name: 'line',          draw: true, group: 'shape', popup: 'temp' }
            ]
            [
                { name: 'rect',             group: 'shape', popup: 'temp' }
                { name: 'triangle',         group: 'shape', popup: 'temp' }
                { name: 'triangle_square',  group: 'shape', popup: 'temp' }
                { name: 'image',            group: 'shape', popup: 'temp' }
                { name: 'circle',           group: 'shape', popup: 'temp' }
                { name: 'ellipse',          group: 'shape', popup: 'temp' }
                { name: 'pie', draw: true,  group: 'shape', popup: 'temp' }
                { name: 'arc', draw: true,  group: 'shape', popup: 'temp' }                
            ]
            [
                { name:  'text',    group: 'shape', popup: 'temp' }
                { class: 'font'   }
                { class: 'anchor' }
            ]
            [
                { class: 'alpha' }
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
                { class: 'padding' }
                { class: 'wire'    }
                { class: 'zoom'    }
                { class: 'layer'   }
                { class: 'grid'    }
                { class: 'show'    }
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
            
        if Exporter.hasSVG cfg.name ? cfg.class
            cfg.svg = Exporter.loadSVG cfg.name ? cfg.class
            
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
        
        @restore()
        
        @clickTool prefs.get 'tool:active', 'pick' 
        
        if prefs.get 'fontlist:visible', false
            @getTool('font').toggleList()
            
        if prefs.get 'layerlist:visible', false
            @getTool('layer').toggleList()
        
        if recent = first prefs.get 'recent', []
            @stage.load recent
            
        if box = prefs.get 'stage:viewbox'
            @stage.zoom = box.zoom
            @stage.setViewBox box
            
        if prefs.get 'browser:open', false
            setImmediate => @kali.openBrowser()
       
    restore: ->
        
        store = prefs.get 'tool:store'
        return if not store?
        
        for names in store
            parent = @getTool first names
            continue if parent.name == 'stroke'
            if not parent.hasChildren()
                parent.swapParent()

            for name in names.slice 1
                child = parent.getTool name 
                index = names.indexOf name
                child.setPos parent.pos().plus pos 66*index, 0
                childIndex = parent.children.indexOf(child)
                parent.children.splice childIndex, 1
                parent.children.splice index, 0, child
                
        @store()
        
    store: ->
        
        store = @children.map (tool) -> 
            [tool.name].concat tool.children.map (child) -> child.name
                    
        prefs.set 'tool:store', store
            
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
        
        prefs.set 'tool:active', name
        
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


# 000       0000000   000   000  00000000  00000000   000      000   0000000  000000000
# 000      000   000   000 000   000       000   000  000      000  000          000   
# 000      000000000    00000    0000000   0000000    000      000  0000000      000   
# 000      000   000     000     000       000   000  000      000       000     000   
# 0000000  000   000     000     00000000  000   000  0000000  000  0000000      000   

{ stopEvent, drag, empty, setStyle, childIndex, prefs, keyinfo, elem, clamp, last, post, log, _ } = require 'kxk'

{ ensureInSize, bboxForItems, winTitle, contrastColor } = require '../utils'

Exporter = require '../exporter'

class LayerList
    
    constructor: (@kali) ->
        
        @stage = @kali.stage
        
        @element = elem 'div', class: 'layerList'
        @element.tabIndex   = 100
        
        @title = winTitle 
            close:  @onClose 
            buttons: [
                text: 'new'
                action: @stage.newLayer
            ,
                text: 'add'
                action: @stage.addLayer
            ,
                text: 'dup'
                action: @stage.duplicateLayer
            ]
            
        @element.appendChild @title 
                
        @element.addEventListener 'mousedown', (event) => stopEvent(event); @element.focus()
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
        @element.addEventListener 'keydown', @onKeyDown
                
        @scroll = elem 'div', class: 'layerListScroll'
        @scroll.addEventListener  'mousedown', @onClick
        @element.appendChild @scroll
        
        @element.appendChild elem class:'layerListFooter'
        
        @kali.insertBelowTools @element
        
        post.on 'resize', @onResize
                    
    onStage: (action, info) =>
        
        switch action
            
            when 'layer', 'moveItems' then @update()
            when 'color' 
                @scroll.style.background = info.hex
                if not empty document.styleSheets
                    setStyle '.layerListLayer.active', 'border-color', contrastColor info.hex
        
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: =>

        @scroll.innerHTML = ''
        
        for index in [0...Math.max(1, @stage.numLayers())]
            @stage.layerAt(index).show()
            
        @viewbox = bboxForItems @stage.items()

        for index in [0...Math.max(1, @stage.numLayers())]
            layer = @stage.layerAt index 
            layer.hide() if layer.data 'hidden'
        
        for index in [0...Math.max(1, @stage.numLayers())]
            @scroll.insertBefore @layerDiv(index), @scroll.firstChild
            
    # 000       0000000   000   000  00000000  00000000   
    # 000      000   000   000 000   000       000   000  
    # 000      000000000    00000    0000000   0000000    
    # 000      000   000     000     000       000   000  
    # 0000000  000   000     000     00000000  000   000  
    
    layerDiv: (index) ->
        
        layer = @stage.layerAt index 
        
        div = elem class:'layerListLayer'
        svg = SVG(div).size '100%', '100%'
        svg.addClass 'layerListSVG'
        if not empty @stage.items()
            svg.svg Exporter.svg layer, viewbox:@viewbox
        
        if index == @stage.layerIndex
            div.classList.add 'active'
            
        left  = elem class: 'layerListMenuLeft'
        right = elem class: 'layerListMenuRight'
            
        addButton = (menu, action, icon) =>
            icon ?= action
            btn = elem class: 'layerListButton', 'mousedown': _.partial @onButtonAction, index, action
            btn.innerHTML = Exporter.loadSVG "layer-#{icon}"
            menu.appendChild btn
        
        addButton left, 'hide',    layer.data('hidden')   and 'hidden'   or 'hide'
        addButton left, 'disable', layer.data('disabled') and 'disabled' or 'disable'

        if @stage.numLayers()
            addButton right, 'delete'
            
        addButton right, 'duplicate'
        addButton right, 'split'
        
        if index > 0
            addButton right, 'merge'
            
        div.appendChild left
        div.appendChild right
            
        div

    onButtonAction: (index, action, event) =>
    
        stopEvent event
        
        switch action
            when 'duplicate' then @stage.duplicateLayer index
            when 'merge'     then @stage.mergeLayer     index
            when 'delete'    then @stage.delLayer       index
            when 'split'     then @stage.addLayer       index
            when 'hide'      then @stage.toggleLayer    index, 'hidden'
            when 'disable'   then @stage.toggleLayer    index, 'disabled'
        
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    active:      -> @scroll.querySelector '.active'
    activeIndex: -> not @active() and -1 or @scroll.children.length - 1 - childIndex @active()
            
    onUndo: (info) => 
        
        if info.action == 'done'
            
            @update() 
            @onResize @stage.viewSize()
    
    onResize: (size) => 
        
        er = @element.getBoundingClientRect()
        sr = @scroll.getBoundingClientRect()
        height = size.y-er.height+sr.height
        @scroll.style.maxHeight = "#{height}px" 
        
    #  0000000  000   000   0000000   000   000
    # 000       000   000  000   000  000 0 000
    # 0000000   000000000  000   000  000000000
    #      000  000   000  000   000  000   000
    # 0000000   000   000   0000000   00     00
    
    isVisible:      -> @element.style.display != 'none'
    toggleDisplay:  -> @setVisible not @isVisible()
    setVisible: (v) -> if v then @show() else @hide()
    hide: -> 
        
        prefs.set 'layerlist:visible', false
        
        post.removeListener 'stage', @onStage
        post.removeListener 'undo',  @onUndo
        
        @element.style.display = 'none'
        @element.blur()
        
    show: -> 
        
        prefs.set 'layerlist:visible', true
        
        post.on 'stage', @onStage
        post.on 'undo',  @onUndo
        
        @element.style.display = 'block'
        @element.focus()
        
        @update()
        
    onClose: => @hide()
            
    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    navigate: (dir) -> @activate @activeIndex() + dir
    activate: (index, opt) -> @stage.activateLayer index

    onClick: (event) => 
        
        @element.focus()
        @activate @scroll.children.length - 1 - childIndex event.target
        stopEvent event
    
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        
        log "layerlist.onKeyDown #{combo}"
        
        switch combo
            
            when 'up'            then @navigate +1
            when 'down'          then @navigate -1
            when 'command+up'    then stopEvent(event); @activate 0
            when 'command+down'  then stopEvent(event); @activate @scroll.children.length-1
            when 'esc', 'enter'  then return @hide()
            # else
                # log combo
                
        if combo.startsWith 'command' then return
                
        stopEvent event
        
module.exports = LayerList

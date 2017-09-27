
# 000       0000000   000   000  00000000  00000000   000      000   0000000  000000000
# 000      000   000   000 000   000       000   000  000      000  000          000   
# 000      000000000    00000    0000000   0000000    000      000  0000000      000   
# 000      000   000     000     000       000   000  000      000       000     000   
# 0000000  000   000     000     00000000  000   000  0000000  000  0000000      000   

{ stopEvent, drag, empty, setStyle, childIndex, prefs, keyinfo, elem, clamp, last, post, log, $, _ } = require 'kxk'

{ ensureInSize, bboxForItems, winTitle, contrastColor } = require '../utils'

Exporter = require '../exporter'

class LayerList
    
    log: -> log.apply log, [].slice.call arguments, 0
    
    constructor: (@kali) ->
        
        @stage = @kali.stage
        
        @element = elem 'div', class: 'layerList'
        @element.tabIndex = 100
        
        @title = winTitle 
            close:  @onClose 
            buttons: [
                text: 'new',  action: => @stage.createLayer selection:'keep'
            ,
                text: 'move', action: => @stage.createLayer selection:'move'
            ,
                text: 'copy', action: => @stage.createLayer selection:'copy'
            ]
            
        @element.appendChild @title 
                
        @element.addEventListener 'mousedown', (event) => @element.focus()
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
        @element.addEventListener 'keydown', @onKeyDown
                
        @scroll = elem 'div', class: 'layerListScroll'
        @scroll.addEventListener  'mousedown', @onClick
        @element.appendChild @scroll
        
        @element.appendChild elem class:'layerListFooter'
        
        @drag = new drag
            target:  @scroll
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop
        
        @kali.insertBelowTools @element
        
        post.on 'resize', @onResize

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (d, e) => 

        index = e.target.index

        return 'skip' if not index?
        
        @dragLayer = @layerAt index
        br = @dragLayer.getBoundingClientRect()
        
        @dragDiv = @dragLayer.cloneNode true
        @dragDiv.startIndex = index
        @dragDiv.stopIndex  = index
        @dragDiv.style.position = 'absolute'
        @dragDiv.style.top      = "#{br.top}px"
        @dragDiv.style.left     = "#{br.left}px"
        @dragDiv.style.width    = "#{br.width}px"
        @dragDiv.style.height   = "#{br.height}px"
        @dragDiv.style.pointerEvents = 'none'
        svg = SVG.adopt @dragDiv.firstChild
        {r,g,b} = new SVG.Color @stage.color
        svg.style 
            'background': "rgba(#{r},#{g},#{b},1)"
        document.body.appendChild @dragDiv
        @dragLayer.style.opacity = '0'

    onDragMove: (d,e) =>
        
        @dragDiv.style.transform = "translateY(#{d.deltaSum.y}px)"
        if layer = @layerAtY d.pos.y
            if layer.index != @dragLayer.index
                @dragDiv.stopIndex = layer.index
                @swapLayers layer, @dragLayer
                        
    onDragStop: (d,e) =>
        
        { startIndex, stopIndex } = @dragDiv
        
        @dragLayer.style.opacity = ''
        @dragDiv.remove()
        delete @dragDiv
        delete @dragLayer
        
        if startIndex != stopIndex

            @stage.moveLayer startIndex, stopIndex
        
    onStage: (action, info) =>
        
        switch action
            
            when 'load'  then @scroll.style.background = @stage.color.toHex()
            when 'layer' then @updateActive info
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

        @log 'LayerList.update', @stage.numLayers()
        
        @scroll.innerHTML = ''
        
        for index in [0...Math.max(1, @stage.numLayers())]
            @stage.layerAt(index).show()
            
        @viewbox = bboxForItems @stage.items()

        for index in [0...Math.max(1, @stage.numLayers())]
            layer = @stage.layerAt index 
            layer.hide() if layer.data 'hidden'
        
        for index in [0...Math.max(1, @stage.numLayers())]
            @scroll.insertBefore @layerDiv(index), @scroll.firstChild

    updateActive: (info) ->
        
        if info.num != @scroll.children.length
            @log 'LayerList.updateActive num differs -> update()'
            @update()
        else
            @log 'LayerList.updateActive highlight', @activeLayer()?
            if @activeLayer()
                @log 'LayerList.updateActive highlight', @activeLayer().index, @activeLayer().className, info
                @activeLayer()?.classList.remove 'active'
            @layerAt(info.active)?.classList.add 'active'
            
    # 000       0000000   000   000  00000000  00000000   
    # 000      000   000   000 000   000       000   000  
    # 000      000000000    00000    0000000   0000000    
    # 000      000   000     000     000       000   000  
    # 0000000  000   000     000     00000000  000   000  
    
    layerDiv: (index) ->
        
        layer = @stage.layerAt index 
        
        div = elem class:'layerListLayer'
        div.index = index
        div.addEventListener 'dblclick', (event) =>
            @stage.selectLayer event.target.index
        
        svg = SVG(div).size '100%', '100%'
        svg.addClass 'layerListSVG'
        if not empty layer.children()
            svg.svg Exporter.svg layer, viewbox:@viewbox
        
        if index == @stage.layerIndex
            div.classList.add 'active'
            
        left  = elem class: 'layerListMenuLeft'
        right = elem class: 'layerListMenuRight'
            
        # 0000000    000   000  000000000  000000000   0000000   000   000  
        # 000   000  000   000     000        000     000   000  0000  000  
        # 0000000    000   000     000        000     000   000  000 0 000  
        # 000   000  000   000     000        000     000   000  000  0000  
        # 0000000     0000000      000        000      0000000   000   000  
        
        addButton = (menu, action, icon) =>
            icon ?= action
            btn = elem class:'layerListButton', 'mousedown': _.partial @onButtonAction, index, action
            btn.innerHTML = Exporter.loadSVG "layer-#{icon}"
            menu.appendChild btn
            btn
        
        hide    = addButton left, 'hide',    layer.data('hidden')   and 'hidden'   or 'hide'
        disable = addButton left, 'disable', layer.data('disabled') and 'disabled' or 'disable'

        opaque = false
        if layer.data 'hidden'
            opaque = true
            hide.classList.add 'active'
            svg.style opacity: 0.1
            
            disable.style.display = 'none'
        else
            hide.classList.remove 'active'
            svg.style opacity: 1
            
            disable.style.display = 'block'
            
        if layer.data 'disabled'
            opaque = true
            disable.classList.add 'active'
        else
            disable.classList.remove 'active'
            
        left.classList.toggle 'opaque', opaque
        
        addButton right, 'duplicate'
        
        if @stage.numLayers() > 1
            addButton right, 'delete'
            
        addButton right, 'split'
        
        if index > 0
            addButton right, 'merge'
            
        div.appendChild left
        div.appendChild right
            
        div

    onButtonAction: (index, action, event) =>
    
        @log 'onButtonAction', event?
        stopEvent event
        
        if event.metaKey
            switch action
                when 'hide'    then return @stage.soloLayer index, 'hidden'
                when 'disable' then return @stage.soloLayer index, 'disabled'

        if event.ctrlKey
            switch action
                when 'hide'    then return @stage.clearState 'hidden'
                when 'disable' then return @stage.clearState 'disabled'
                
        switch action
            when 'duplicate' then @stage.duplicateLayer index
            when 'merge'     then @stage.mergeLayer     index
            when 'delete'    then @stage.delLayer       index
            when 'split'     then @stage.splitLayer     index
            when 'hide'      then @stage.toggleLayer    index, 'hidden'
            when 'disable'   then @stage.toggleLayer    index, 'disabled'
        
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    activeLayer: -> $ @scroll, '.layerListLayer.active'
    activeIndex: -> not @activeLayer() and -1 or @swapIndex childIndex @activeLayer()
    
    layerAt:   (index) -> @scroll.children[@swapIndex index]
    layerAtY: (y) => 
    
        _.find @scroll.children, (layer) -> 
            br = layer.getBoundingClientRect()
            br.top <= y <= br.top + br.height
    
    #  0000000  000   000   0000000   00000000   
    # 000       000 0 000  000   000  000   000  
    # 0000000   000000000  000000000  00000000   
    #      000  000   000  000   000  000        
    # 0000000   00     00  000   000  000        
    
    swapIndex:  (index) -> @scroll.children.length - 1 - index
    swapLayers: (layerA, layerB) -> 
        
        return if not layerA? or not layerB?
        return if layerA == layerB
        if layerA.index > layerB.index
            @scroll.insertBefore layerB, layerA
            @scroll.insertBefore layerA, @scroll.children[@swapIndex layerB.index]
        else
            @scroll.insertBefore layerA, layerB
            @scroll.insertBefore layerB, @scroll.children[@swapIndex layerA.index]
        [layerA.index, layerB.index] = [layerB.index, layerA.index]
                  
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
        
        @scroll.style.background = @stage.color.toHex()
        
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
        
        @log "LayerList.onKeyDown #{combo}"
        
        switch combo
            
            when 'up'            then @navigate +1
            when 'down'          then @navigate -1
            when 'command+up',   'page up'   then stopEvent(event); @activate @scroll.children.length-1
            when 'command+down', 'page down' then stopEvent(event); @activate 0
            # else
                # log combo
                
        if combo.startsWith 'command' then return
                
        stopEvent event
       
module.exports = LayerList


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
                action: @stage.dupLayer
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
        # log 'layerlist.update'
        @scroll.innerHTML = ''
        for index in [0...Math.max(1, @stage.numLayers())]
            @scroll.insertBefore @layerDiv(index), @scroll.firstChild
            
        @onResize @stage.viewSize()
        @active()?.scrollIntoViewIfNeeded false
        
    # 000       0000000   000   000  00000000  00000000   
    # 000      000   000   000 000   000       000   000  
    # 000      000000000    00000    0000000   0000000    
    # 000      000   000     000     000       000   000  
    # 0000000  000   000     000     00000000  000   000  
    
    layerDiv: (index) ->
        
        div = elem class:'layerListLayer'
        svg = SVG(div).size '100%', '100%'
        svg.addClass 'layerListSVG'
        svg.svg Exporter.svg @stage.layerAt(index), viewbox:bboxForItems @stage.svg.children()
        
        if index == @stage.layerIndex
            div.classList.add 'active'
            
        menu = elem class: 'layerListMenu', children: [ 
            elem class: 'layerListButton', text: 'X', 'mousedown': _.partial @onButtonAction, index, 'delete'
            elem class: 'layerListButton', text: 'M', 'mousedown': _.partial @onButtonAction, index, 'merge'
            elem class: 'layerListButton', text: 'V', 'mousedown': _.partial @onButtonAction, index, 'visible'            
            elem class: 'layerListButton', text: 'E', 'mousedown': _.partial @onButtonAction, index, 'enabled'
        ]
        
        div.appendChild menu
        div

    onButtonAction: (index, action, event) =>
        
        log "onButtonAction #{index} #{action} #{event?}"
        stopEvent event
        
        switch action
            when 'delete'  then @stage.delLayer    index
            when 'merge'   then @stage.mergeLayer  index
            when 'visible' then @stage.toggleLayer index, 'visible'
            when 'enabled' then @stage.toggleLayer index, 'enabled'
        
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    active:      -> @scroll.querySelector '.active'
    activeIndex: -> not @active() and -1 or @scroll.children.length - 1 - childIndex @active()
            
    onUndo: (action) => @update() if action == 'done'
    onResize: (size) => 
        
        er = @element.getBoundingClientRect()
        sr = @scroll.getBoundingClientRect()
        @scroll.style.maxHeight = "#{size.y-er.height+sr.height}px" 

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

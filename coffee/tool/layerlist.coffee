
# 000       0000000   000   000  00000000  00000000   000      000   0000000  000000000
# 000      000   000   000 000   000       000   000  000      000  000          000   
# 000      000000000    00000    0000000   0000000    000      000  0000000      000   
# 000      000   000     000     000       000   000  000      000       000     000   
# 0000000  000   000     000     00000000  000   000  0000000  000  0000000      000   

{ stopEvent, childIndex, prefs, keyinfo, elem, drag, clamp, last, post, log, _ } = require 'kxk'

{ bboxForItems, winTitle } = require '../utils'

Exporter = require '../exporter'

class LayerList
    
    constructor: (@kali) ->
        
        @stage = @kali.stage
        
        @element = elem 'div', class: 'layerList'
        @element.style.left = "#{prefs.get 'layerlist:pos:x', 64}px"
        @element.style.top  = "#{prefs.get 'layerlist:pos:y', 34}px"
        @element.tabIndex   = 100
        
        @title = winTitle close:@onClose, buttons: [
            text: 'new'
            action: @newLayer
        ,
            text: 'del'
            action: @delLayer
        ]
            
        @element.appendChild @title 
        
        @drag = new drag
            target: @element
            onMove: (drag) => 
                x = parseInt(@element.style.left) + drag.delta.x
                y = parseInt(@element.style.top)  + drag.delta.y
                prefs.set 'layerlist:pos:x', x
                prefs.set 'layerlist:pos:y', y
                @element.style.left = "#{x}px"
                @element.style.top  = "#{y}px"
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
        @element.addEventListener 'keydown', @onKeyDown
                
        @scroll = elem 'div', class: 'layerListScroll'
        @scroll.addEventListener  'click', @onClick
        @element.appendChild @scroll
        
        @element.appendChild elem class:'layerListFooter'
        
        @kali.insertBelowTools @element
        
    onStage: (action, info) =>
        
        switch action 
            
            when 'layer' then @refreshLayers()
            when 'color' then @scroll.style.background = info.hex
        
    refreshLayers: ->
        
        @scroll.innerHTML = ''
        for index in [0...Math.max(1, @stage.numLayers())]
            layerDiv = elem class:'layerListLayer'
            layerSvg = SVG(layerDiv).size '100%', '100%'
            layerSvg.addClass 'layerListLayerSVG'
            layerSvg.svg Exporter.svg @stage.layerAt(index), viewbox:bboxForItems @stage.items()
            
            log "layer #{index}", layerSvg.children().length
            @scroll.insertBefore layerDiv, @scroll.firstChild
        
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
        
        @element.style.display = 'none'
        @element.blur()
        
    show: -> 
        
        prefs.set 'layerlist:visible', true
        
        post.on 'stage', @onStage
        
        @element.style.display = 'block'
        @element.focus()
        
        @refreshLayers()
        @active()?.scrollIntoViewIfNeeded false
        
    onClose: => @hide()
    
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    active: -> @scroll.querySelector '.active'
    activeIndex: -> not @active() and -1 or childIndex @active()
        
    # 000   000   0000000   000   000  000   0000000    0000000   000000000  00000000  
    # 0000  000  000   000  000   000  000  000        000   000     000     000       
    # 000 0 000  000000000   000 000   000  000  0000  000000000     000     0000000   
    # 000  0000  000   000     000     000  000   000  000   000     000     000       
    # 000   000  000   000      0      000   0000000   000   000     000     00000000  
    
    navigate: (dir) -> @select @activeIndex() + dir

    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    select: (index, opt) ->
        
        index = clamp 0, @scroll.children.length-1, index
        @active()?.classList.remove 'active'
        @scroll.children[index].classList.add 'active'
        @active().scrollIntoViewIfNeeded false
        if opt?.emit != false
            post.emit 'layer', 'active', @activeIndex()
        prefs.set "layerlist:selected", index

    onClick: (event) => @select childIndex event.target
    
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        
        switch combo
            
            when 'up'            then @navigate -1
            when 'down'          then @navigate +1
            when 'command+up'    then stopEvent(event); @select 0
            when 'command+down'  then stopEvent(event); @select @scroll.children.length-1
            when 'esc', 'enter'  then return @hide()
            # else
                # log combo
                
        if combo.startsWith 'command' then return
                
        stopEvent event
        
module.exports = LayerList

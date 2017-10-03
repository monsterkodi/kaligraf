
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  000      000   0000000  000000000
# 000        000   000  000   000  000   000  000  000       0000  000     000     000      000  000          000   
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     000      000  0000000      000   
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000      000       000     000   
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     0000000  000  0000000      000   

{ stopEvent, setStyle, childIndex, upElem, drag, childIndex, prefs, keyinfo, elem, empty, clamp, post, pos, log, $, _ } = require 'kxk'

{ ensureInSize, winTitle, boundingBox, boxPos, highlightColor } = require '../utils'

GradientItem = require './gradientitem'
Exporter     = require '../exporter'
Shadow       = require '../shadow'

class GradientList
    
    log: -> log.apply log, [].slice.call arguments, 0
    
    constructor: (@kali) ->
        
        @stage = @kali.stage
        
        @element = elem 'div', class: 'gradientList'
        @setPos pos prefs.get('gradientlist:pos:x', 64), prefs.get('gradientlist:pos:y', 34)
        @element.tabIndex = 100
        
        @title = winTitle 
            close:  @onClose 
            buttons: [
                text: 'new',  action: @onNewGradient
            ,
                text: 'copy', action: @onCopyGradient
            ,
                text: 'del',  action: @onDelGradient
            ]
            
        @element.appendChild @title 
                
        @element.addEventListener 'mousedown', (event) => @element.focus()
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
        @element.addEventListener 'keydown', @onKeyDown
                
        @scroll = elem 'div', class: 'gradientListScroll'
        @scroll.addEventListener  'mousedown', @onClick
        @element.appendChild @scroll
        
        @element.appendChild elem class:'gradientListFooter'
        
        @drag = new drag
            target:  @scroll
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop
            
        @titleDrag = new drag
            target: @title
            onMove: (drag) => 
                newPos = boxPos(boundingBox @element).plus drag.delta
                prefs.set 'gradientlist:pos:x', newPos.x
                prefs.set 'gradientlist:pos:y', newPos.y
                @setPos newPos
                @shadow.update()

        @kali.insertBelowTools @element
        @shadow = new Shadow @element
        
        post.on 'resize', @onResize
        post.on 'stage',  @onStage
        
        @updateColor()
        @restore()
        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (drag, event) => 

        @dragGradient = upElem event.target, prop: 'gradient'

        return 'skip' if not @dragGradient?
        
        index = childIndex @dragGradient
        
        br = @dragGradient.getBoundingClientRect()
        
        @dragDiv = @dragGradient.cloneNode true
        @dragDiv.startIndex = index
        @dragDiv.stopIndex  = index
        @dragDiv.style.position = 'absolute'
        @dragDiv.style.top      = "#{br.top}px"
        @dragDiv.style.left     = "#{br.left}px"
        @dragDiv.style.width    = "#{br.width}px"
        @dragDiv.style.height   = "#{br.height}px"
        @dragDiv.style.pointerEvents = 'none'
        @dragDiv.style.zIndex   = 9999
        document.body.appendChild @dragDiv
        @dragGradient.style.opacity = '0'

    onDragMove: (drag,event) =>
        
        @dragDiv.style.transform = "translateY(#{drag.deltaSum.y}px)"
        if gradient = @gradientAtY drag.pos.y
            if childIndex(gradient) != childIndex(@dragGradient)
                @dragDiv.stopIndex = childIndex gradient
                @swapGradients gradient, @dragGradient
                        
    onDragStop: (drag,event) =>
        
        { startIndex, stopIndex } = @dragDiv
        
        @dragGradient.style.opacity = ''
        @dragDiv.remove()
        delete @dragDiv
        delete @dragGradient
        
    #  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  
    # 000        000   000  000   000  000   000  000  000       0000  000     000     
    # 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     
    # 000   000  000   000  000   000  000   000  000  000       000  0000     000     
    #  0000000   000   000  000   000  0000000    000  00000000  000   000     000     

    onNewGradient: =>
        index = @activeIndex()
        gradient = new GradientItem @
        @scroll.insertBefore gradient.element, @activeGradient()
        @activate Math.max 0, index
        @store()
        
    onCopyGradient: => 
        
        index = @activeIndex()
        return if index < 0
        
        gradient = new GradientItem @
        gradient.setGradient @activeGradient().gradient.state()
        @scroll.insertBefore gradient.element, @activeGradient()
        @activate index
        @store()
        
    onDelGradient:  =>
        
        index = @activeIndex()
        return if index < 0
        
        if @activeGradient().gradient.activeStop()?
            @activeGradient().gradient.delStop()
        else
            @activeGradient().remove()
            @activate index
            @store()
         
    gradientItems: -> 
        
        items = []
        if not empty @scroll.children
            for child in @scroll.children
                items.push child.gradient
        items
        
    store: ->
        prefs.set 'gradient:active', @activeIndex()
        prefs.set 'gradient:list', @gradientItems().map (gradient) -> gradient.state()
        @shadow.update()
        
    restore: ->
        for state in prefs.get 'gradient:list', []
            gradient = new GradientItem @
            gradient.restore state
            @scroll.appendChild gradient.element
        @activate prefs.get 'gradient:active', 0
        
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    activeGradient: -> $ @scroll, '.gradientItem.active'
    activeIndex: -> not @activeGradient() and -1 or childIndex @activeGradient()

    activeItem: -> @itemAt @activeIndex()
    itemAt: (index) -> @gradientAt(index)?.gradient
    
    gradientAt: (index) -> @scroll.children[index]
    gradientAtY: (y) => 
    
        _.find @scroll.children, (gradient) -> 
            br = gradient.getBoundingClientRect()
            br.top <= y <= br.top + br.height
    
    #  0000000  000   000   0000000   00000000   
    # 000       000 0 000  000   000  000   000  
    # 0000000   000000000  000000000  00000000   
    #      000  000   000  000   000  000        
    # 0000000   00     00  000   000  000        
    
    swapGradients: (gradientA, gradientB) -> 
        
        return if not gradientA? or not gradientB?
        return if gradientA == gradientB
        if childIndex(gradientA) > childIndex(gradientB)
            @scroll.insertBefore gradientB, gradientA
            @scroll.insertBefore gradientA, @scroll.children[childIndex(gradientB)]
        else
            @scroll.insertBefore gradientA, gradientB
            @scroll.insertBefore gradientB, @scroll.children[childIndex(gradientA)]
                  
    # 00000000   00000000   0000000  000  0000000  00000000  
    # 000   000  000       000       000     000   000       
    # 0000000    0000000   0000000   000    000    0000000   
    # 000   000  000            000  000   000     000       
    # 000   000  00000000  0000000   000  0000000  00000000  
    
    onResize: => 
        
        size = @stage.viewSize()

        br = boundingBox @element
        newPos = boxPos br
        
        if br.x < 0 then newPos.x = 0
        else if br.x + br.w > size.x then newPos.x = Math.max 0, size.x - br.w
        
        if br.y < 0 then newPos.y = 0
        else if br.y + br.h > size.y then newPos.y = Math.max 0, size.y - br.h
            
        @setPos newPos
        @shadow.update()

    setPos: (p) -> @element.style.transform = "translate(#{p.x}px, #{p.y}px)"

    #  0000000   0000000   000       0000000   00000000   
    # 000       000   000  000      000   000  000   000  
    # 000       000   000  000      000   000  0000000    
    # 000       000   000  000      000   000  000   000  
    #  0000000   0000000   0000000   0000000   000   000  
    
    onStage: (action) =>
        
        switch action
            when 'color' then @updateColor()
    
    updateColor: ->
        
        # hex = @stage.color.toHex()
        # if not empty document.styleSheets
            # setStyle '.gradientItem.active', 'border-color', highlightColor hex
    
    #  0000000  000   000   0000000   000   000
    # 000       000   000  000   000  000 0 000
    # 0000000   000000000  000   000  000000000
    #      000  000   000  000   000  000   000
    # 0000000   000   000   0000000   00     00
    
    isVisible:      -> @element.style.display != 'none'
    toggleDisplay:  -> @setVisible not @isVisible()
    setVisible: (v) -> if v then @show() else @hide()
    hide: -> 
        
        prefs.set 'gradientlist:visible', false
        
        @element.style.display = 'none'
        @shadow.update()
        @kali.focus()
        
    show: -> 
        
        prefs.set 'gradientlist:visible', true
        
        @element.style.display = 'block'
        @onResize()
        # @shadow.update()
        @element.focus()
        
    onClose: => @hide()
            
    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    navigate: (dir) -> @activate @activeIndex() + dir
    
    activate: (index, opt) ->
        
        index = clamp 0, @scroll.children.length-1, index
        
        @activeItem()?.setActive false
        @itemAt(index).setActive true
        
        prefs.set 'gradient:active', @activeIndex()
            
    onClick: (event) => 
        
        @element.focus()
        @activate childIndex event.target
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
            
            when 'up'            then @navigate -1
            when 'down'          then @navigate +1
            when 'backspace', 'delete', 'd'  then @onDelGradient()
            when 'n'                         then @onNewGradient()
            when 'c'                         then @onCopyGradient()
            when 'esc'                       then @hide()
            when 'command+up',   'page up'   then stopEvent(event); @activate 0
            when 'command+down', 'page down' then stopEvent(event); @activate @scroll.children.length-1
            # else
                # log combo
                
        if combo.startsWith 'command' then return
                
        stopEvent event
       
module.exports = GradientList

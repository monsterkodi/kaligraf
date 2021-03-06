###
 0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  000      000   0000000  000000000
000        000   000  000   000  000   000  000  000       0000  000     000     000      000  000          000   
000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     000      000  0000000      000   
000   000  000   000  000   000  000   000  000  000       000  0000     000     000      000       000     000   
 0000000   000   000  000   000  0000000    000  00000000  000   000     000     0000000  000  0000000      000   
###

{ post, stopEvent, keyinfo, prefs, empty, clamp, elem, kpos, drag, $, _ } = require 'kxk'

{   gradientStops, gradientState, gradientType,
    ensureInSize, winTitle, boundingBox, boxPos, highlightColor, invertColor } = require '../utils'

GradientItem = require './gradientitem'
Exporter     = require '../exporter'
Shadow       = require '../shadow'

class GradientList
    
    log: -> #log.apply log, [].slice.call arguments, 0
    
    constructor: (@kali) ->
        
        @stage = @kali.stage
        
        @element = elem 'div', class: 'gradientList'
        @setPos kpos prefs.get 'gradientlist:pos', kpos 64, 34
        @element.tabIndex = 100
        
        @title = winTitle 
            close:  @onClose 
            buttons: [
                text: 'new',  action: @onNewGradient
            ,
                text: 'copy', action: @onCopyGradient
            ,
                text: 'rev',  action: @onReverseGradient
            ,
                text: 'inv',  action: @onInvertGradient
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
                elemPos = kpos parseInt(@element.style.left), parseInt(@element.style.top) 
                newPos  = elemPos.plus drag.delta
                prefs.set 'gradientlist:pos', newPos
                @setPos newPos
                @shadow.update()

        @kali.insertBelowTools @element
        @shadow = new Shadow @element
        
        post.on 'resize', @onResize
        post.on 'stage', (action) => if action == 'load' then @restore() 
        
        @restore()
        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (drag, event) => 

        @dragGradient = elem.upElem event.target, prop: 'gradient'

        return 'skip' if not @dragGradient?
        
        index = elem.childIndex @dragGradient
        
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
            if elem.childIndex(gradient) != elem.childIndex(@dragGradient)
                @dragDiv.stopIndex = elem.childIndex gradient
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
        gradient = new GradientItem @kali
        
        gradient.setGradient type:'linear', stops: [
                offset:0, color:@kali.tools.fill.color, opacity:1
            ,
                offset:1, color:@kali.tools.stroke.color, opacity:1
            ]
        
        @scroll.insertBefore gradient.element, @activeGradient()
        @activate Math.max 0, index
        @store()
        
    onCopyGradient: => 
        
        index = @activeIndex()
        return if index < 0
        
        gradient = new GradientItem @kali
        gradient.setGradient @activeGradient().gradient.state()
        @scroll.insertBefore gradient.element, @activeGradient()
        @activate index
        @store()

    onReverseGradient: => 
        
        if gradient = @activeGradient()?.gradient.gradient
            stops = gradientStops gradient
            gradient.update (stop) ->
                for stp in stops.reverse()
                    stop.at (1-stp.offset), stp.color, stp.opacity
            @activeGradient().gradient.createStops()
            @store()

    onInvertGradient: => 
        
        if gradient = @activeGradient()?.gradient.gradient
            stops = gradientStops gradient
            gradient.update (stop) ->
                for stp in stops
                    stop.at stp.offset, invertColor(stp.color), stp.opacity
            @activeGradient().gradient.update()
            @store()
            
    onDelStopOrGradient: =>
    
        index = @activeIndex()
        return if index < 0
        
        if @activeGradient().gradient.activeStop()? and @activeGradient().gradient.numStops() > 1
            @activeGradient().gradient.delStop()
        else
            @activeItem().del()
            @activate index
            @store()
        
    onDelGradient: =>
        
        index = @activeIndex()
        return if index < 0
        
        @activeItem().del()
        @activate index
        @store()
         
    gradientItems: -> 
        
        items = []
        if not empty @scroll.children
            for child in @scroll.children
                items.push child.gradient
        items
        
    #  0000000  000000000   0000000   00000000   00000000  
    # 000          000     000   000  000   000  000       
    # 0000000      000     000   000  0000000    0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000      0000000   000   000  00000000  
    
    store: -> @shadow.update()
        
    restore: -> 
                
        stopList = []
        
        for item in @stage.svg.defs().children()
            
            if item.type in ['linearGradient', 'radialGradient', 'linear', 'radial']
                stopList.push gradientStops item
            
        stopList = _.uniqWith stopList, _.isEqual
        
        @scroll.innerHTML = ''
        
        for stops in stopList
            gradient = new GradientItem @kali
            gradient.restore 
                type:   'linear'
                stops:  stops
            @scroll.appendChild gradient.element
            
        @shadow.update()
        
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    activeGradient: -> $ @scroll, '.gradientItem.active'
    activeIndex: -> not @activeGradient() and -1 or elem.childIndex @activeGradient()

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
        if elem.childIndex(gradientA) > elem.childIndex(gradientB)
            @scroll.insertBefore gradientB, gradientA
            @scroll.insertBefore gradientA, @scroll.children[elem.childIndex(gradientB)]
        else
            @scroll.insertBefore gradientA, gradientB
            @scroll.insertBefore gradientB, @scroll.children[elem.childIndex(gradientA)]
                  
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

    setPos: (p) -> 
        
        @element.style.left = "#{p.x}px"
        @element.style.top  = "#{p.y}px"
    
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
        @element.focus()
        
    onClose: => 
        
        @kali.closeStopPalette()
        @hide()
            
    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    navigate: (dir) -> @activate @activeIndex() + dir
    
    activate: (index, opt) ->
        
        index = clamp 0, @scroll.children.length-1, index
        
        @activeItem()?.setActive false
        @itemAt(index)?.setActive true
        @scrollToActive()
        
        prefs.set 'gradientlist:active', @activeIndex()
        
        @kali.closeStopPalette()
            
    onClick: (event) => 
        
        @element.focus()
        @activate elem.childIndex event.target
        stopEvent event
    
    scrollToActive: ->
        
        index = @activeIndex()
        return if index < 0
        scrollBox = boundingBox @scroll 
        activeBox = boundingBox @activeGradient()
        if activeBox.y < scrollBox.y
            @scroll.scrollTop -= scrollBox.y - activeBox.y
        else if activeBox.y2 > scrollBox.y2
            @scroll.scrollTop += activeBox.y2 - scrollBox.y2
        
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        
        @log "GradientList.onKeyDown #{combo}"
        
        switch combo
            
            when 'up'                     then @navigate -1
            when 'down'                   then @navigate +1
            when 'backspace', 'delete'    then @onDelStopOrGradient()
            when 'n'                      then @onNewGradient()
            when 'c'                      then @onCopyGradient()
            when 'esc'                    then @hide()
            when 'ctrl+up',   'page up'   then stopEvent(event); @activate 0
            when 'ctrl+down', 'page down' then stopEvent(event); @activate @scroll.children.length-1
            # else
                # log combo
                
        if combo.startsWith 'ctrl' then return
                
        stopEvent event
       
module.exports = GradientList

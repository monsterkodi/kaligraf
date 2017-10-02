
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  000      000   0000000  000000000
# 000        000   000  000   000  000   000  000  000       0000  000     000     000      000  000          000   
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     000      000  0000000      000   
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000      000       000     000   
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     0000000  000  0000000      000   

{ stopEvent, drag, childIndex, prefs, keyinfo, elem, empty, clamp, post, log, $, _ } = require 'kxk'

{ ensureInSize, winTitle } = require '../utils'

Exporter = require '../exporter'

GradientItem = require './gradientitem'

class GradientList
    
    log: -> log.apply log, [].slice.call arguments, 0
    
    constructor: (@kali) ->
        
        @stage = @kali.stage
        
        @element = elem 'div', class: 'gradientList'
        @element.style.left = "#{prefs.get 'gradientlist:pos:x', 64}px"
        @element.style.top  = "#{prefs.get 'gradientlist:pos:y', 34}px"        
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
                x = parseInt(@element.style.left) + drag.delta.x
                y = parseInt(@element.style.top)  + drag.delta.y
                prefs.set 'gradientlist:pos:x', x
                prefs.set 'gradientlist:pos:y', y
                @element.style.left = "#{x}px"
                @element.style.top  = "#{y}px"            
        
        @kali.insertAboveTools @element
        
        post.on 'resize', @onResize
        
        @restore()
        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (d, e) => 

        index = e.target.index

        return 'skip' if not index?
        
        @dragGradient = @gradientAt index
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
        svg = SVG.adopt @dragDiv.firstChild
        {r,g,b} = new SVG.Color @stage.color
        svg.style 
            'background': "rgba(#{r},#{g},#{b},1)"
        document.body.appendChild @dragDiv
        @dragGradient.style.opacity = '0'

    onDragMove: (d,e) =>
        
        @dragDiv.style.transform = "translateY(#{d.deltaSum.y}px)"
        if gradient = @gradientAtY d.pos.y
            if gradient.index != @dragGradient.index
                @dragDiv.stopIndex = gradient.index
                @swapGradients gradient, @dragGradient
                        
    onDragStop: (d,e) =>
        
        { startIndex, stopIndex } = @dragDiv
        
        @dragGradient.style.opacity = ''
        @dragDiv.remove()
        delete @dragDiv
        delete @dragGradient
        
        if startIndex != stopIndex

            @stage.moveLayer startIndex, stopIndex
                            
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
        gradient.setGradient @activeGradient().gradient.gradient
        @scroll.insertBefore gradient.element, @activeGradient()
        @activate index
        @store()
        
    onDelGradient:  =>
        
        index = @activeIndex()
        return if index < 0
        @activeGradient().remove()
        @activate index
        log "GradientList.onDelGradient index:#{index}"
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
        log 'store:', prefs.get 'gradient:list'
        
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
        if gradientA.index > gradientB.index
            @scroll.insertBefore gradientB, gradientA
            @scroll.insertBefore gradientA, @scroll.children[gradientB.index]
        else
            @scroll.insertBefore gradientA, gradientB
            @scroll.insertBefore gradientB, @scroll.children[gradientA.index]
        [gradientA.index, gradientB.index] = [gradientB.index, gradientA.index]
                  
    onResize: (size) => ensureInSize @element, size
        
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
        @kali.focus()
        
    show: -> 
        
        prefs.set 'gradientlist:visible', true
        
        @element.style.display = 'block'
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
        @activeGradient()?.classList.remove 'active'
        @gradientAt(index)?.classList.add 'active'
        
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

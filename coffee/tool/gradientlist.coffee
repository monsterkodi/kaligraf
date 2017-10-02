
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  000      000   0000000  000000000
# 000        000   000  000   000  000   000  000  000       0000  000     000     000      000  000          000   
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     000      000  0000000      000   
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000      000       000     000   
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     0000000  000  0000000      000   

{ stopEvent, drag, empty, setStyle, childIndex, prefs, keyinfo, elem, clamp, last, post, log, $, _ } = require 'kxk'

{ ensureInSize, bboxForItems, winTitle, contrastColor } = require '../utils'

Exporter = require '../exporter'

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

    onNewGradient:  =>
        index = @activeIndex()
        @scroll.insertBefore @gradientDiv(), @activeGradient()
        @activate index
        
    onCopyGradient: => 
        index = @activeIndex()
        return if index < 0
        @scroll.insertBefore @gradientDiv(), @activeGradient()
        @activate index
        
    onDelGradient:  =>
        index = @activeIndex()
        return if index < 0
        @activeGradient().remove()
        @activate index
    
    gradientDiv: ->
        
        div = elem class:'gradientListGradient'
        
        svg = SVG(div).size '100%', '100%'
        svg.addClass 'gradientListSVG'
        svg.viewbox x:0,y:0,width:100,height:25
        
        @gradient = svg.gradient 'linear', (stop) =>
            stop.at 0.0, new SVG.Color r:0, g:0, b:0
            stop.at 1.0, @kali.tool('fill').color
        
        @grd = svg.rect()
        @grd.fill @gradient
        @grd.width  100
        @grd.height 25
        
        div
        
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    activeGradient: -> $ @scroll, '.gradientListGradient.active'
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
        @log "GradientList.activate", index, opt
        @activeGradient()?.classList.remove 'active'
        @gradientAt(index)?.classList.add 'active'
            
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

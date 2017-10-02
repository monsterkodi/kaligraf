
# 000000000   0000000    0000000   000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000      0000000    0000000   0000000

{ fileExists, upElem, downElem, stopEvent, elem, drag, post, first, last, fs, pos, log, $, _ } = require 'kxk'

{ elemProp } = require '../utils'

Exporter = require '../exporter'

class Tool

    constructor: (@kali, @cfg) ->

        @name   = @cfg.name ? @cfg.class
        @stage  = @kali.stage 
        @draw   = @cfg.draw
        @group  = @cfg.group
        @action = @cfg.action
        @active = false
                
        @element = elem 'div', class: @name
        @element.classList.add 'tool'
        @element.classList.add 'down' if @cfg.orient == 'down'
        @element.addEventListener 'mouseenter', @onMouseEnter
        @element.addEventListener 'mouseleave', @onMouseLeave
        @element.addEventListener 'wheel', (event) => stopEvent event
        
        @kali.toolDiv.appendChild @element
        
        if @cfg.svg?
            @setSVG @cfg.svg
        else if not @cfg.class?
            @initTitle _.capitalize @cfg.name
        
        @drag = new drag
            target:  @element
            onStart: @dragStart
            onMove:  @dragMove
            onStop:  @dragStop

    bindStage: (mthds) ->
        
        mthds = [mthds] if not _.isArray mthds
        for mthd in mthds
            @stage[mthd] = @constructor.prototype[mthd].bind @stage
             
    #  0000000  00000000   000  000   000  
    # 000       000   000  000  0000  000  
    # 0000000   00000000   000  000 0 000  
    #      000  000        000  000  0000  
    # 0000000   000        000  000   000  
    
    initSpin: (spin) ->
        
        spin.step ?= [1,5,10,50]
        
        span = @initButtons [
            tiny:   'spin-minus'
            button: true
            name:   spin.name + ' minus'
            action: @onSpin
            spin:   spin
        ,
            name:   spin.name + ' reset'
            action: @onSpin
            spin:   spin
        , 
            tiny:   'spin-plus'
            name:   spin.name + ' plus'
            button: true
            action: @onSpin
            spin:   spin
        ]
        
        @button(spin.name + ' reset').innerHTML = spin.str? and spin.str(spin.value) or spin.value
        
        span.addEventListener 'wheel', @onSpinWheel
        
    onSpinWheel: (event) => 
        
        if Math.abs(event.deltaX) >= Math.abs(event.deltaY)
            delta = event.deltaX
        else
            delta = -event.deltaY
        
        button = upElem event.target, prop:'spin'
        spin = button.spin
        step = spin.step[0]
        
        spin.wheel ?= 0
        spin.wheel = spin.wheel + delta * 0.01

        if Math.abs(spin.wheel) >= step
            if delta > 0
                delta = Math.floor(spin.wheel/step)*step
            else
                delta = Math.ceil(spin.wheel/step)*step
            spin.value = Math.round((spin.value + delta)/step)*step
            spin.wheel -= delta
            @doSpin spin
                
    onSpin: (event) => 
        
        stopEvent event
        button = upElem event.target, prop:'spin'
        
        spin = button.spin
        name = button.name
        
        part = last name.split ' '
        
        step = spin.step[0]
        step = spin.step[1] if event.metaKey
        step = spin.step[2] if event.altKey
        step = spin.step[3] if event.ctrlKey
            
        switch part
            when 'minus'
                spin.value = Math.round((spin.value - step)/step)*step
            when 'plus'
                spin.value = Math.round((spin.value + step)/step)*step
            when 'reset'
                if _.isArray spin.reset
                    if spin.value == first spin.reset
                        spin.reset.push spin.reset.shift()
                    spin.value = first spin.reset
                else
                    spin.value = spin.reset
                    
        @doSpin spin
           
    doSpin: (spin) ->
        
        @setSpinValue spin, spin.value
        
        spin.action spin.value
    
    getSpin: (name) -> downElem(@element, prop:'name', value:name+' reset')?.spin
        
    setSpinValue: (spin, value) ->
    
        if _.isString spin then spin = @getSpin spin
        
        spin.value = value
        
        if spin.min? 
            
            spin.value = Math.max spin.value, spin.min
            
            if spin.value <= spin.min
                @hideButton spin.name + ' minus'
            else
                @showButton spin.name + ' minus'
                
        if spin.max? 
            
            spin.value = Math.min spin.value, spin.max
            
            if spin.value >= spin.max
                @hideButton spin.name + ' plus'
            else
                @showButton spin.name + ' plus'
                
        if spin.str?
            valueStr = spin.str spin.value  
        else
            if (spin.value * 100) % 10
                valueStr = spin.value.toFixed 2
            else if (spin.value * 10) % 10
                valueStr = spin.value.toFixed 1
            else
                valueStr = spin.value.toFixed 0
            
        @button(spin.name + ' reset').innerHTML = valueStr
       
    disableSpin: (spin) ->
        
        if _.isString spin then spin = @getSpin spin
        
        @hideButton spin.name + ' minus'
        @hideButton spin.name + ' reset'
        @hideButton spin.name + ' plus'
        
    enableSpin: (spin) ->
        
        if _.isString spin then spin = @getSpin spin
        
        @showButton spin.name + ' minus'
        @showButton spin.name + ' reset'
        @showButton spin.name + ' plus'
        
    # 0000000    000   000  000000000  000000000   0000000   000   000   0000000  
    # 000   000  000   000     000        000     000   000  0000  000  000       
    # 0000000    000   000     000        000     000   000  000 0 000  0000000   
    # 000   000  000   000     000        000     000   000  000  0000       000  
    # 0000000     0000000      000        000      0000000   000   000  0000000   
    
    initButtons: (buttons) ->
        
        span = elem class: 'toolButtons'
        for button in buttons
            btn = elem 'span'
            btn.innerHTML = button.text   if button.text?
            btn.name      = button.name   if button.name?
            
            if button.action?
                btn.classList.add 'toolButton'
                btn.action = button.action
            else
                btn.classList.add 'toolLabel'
                                
            if button.toggle?
                btn.toggle = button.toggle
                btn.classList.add 'toolToggle'
                btn.classList.toggle 'active', btn.toggle

            if button.choice?
                btn.choice = button.choice
                btn.toggle = btn.choice == btn.name
                btn.classList.add 'toolToggle'
                btn.classList.toggle 'active', btn.toggle
                
            if button.icon? or button.tiny? or button.small?
                svg = button.icon ? button.tiny ? button.small
                if Exporter.hasSVG svg
                    btn.innerHTML = Exporter.loadSVG svg
                else
                    btn.innerHTML = Exporter.loadSVG 'rect'
                btn.classList.add 'toolIcon'
                btn.classList.add 'toolTiny' if button.tiny?
                btn.classList.add 'toolSmall' if button.small?
                btn.classList.remove 'toolButton' if not button.button
                btn.firstChild.classList.add 'toolIconSVG'
                btn.icon = button.icon ? button.tiny

            if button.spin? 
                btn.spin = button.spin
                if not btn.name.endsWith 'reset'
                    btn.classList.add 'toolSpinButton' 
                            
            btn.addEventListener 'mousedown', @onButtonClick

            span.appendChild btn
            
        @element.appendChild span
        span
     
    button: (name) ->
        
        for btn in @element.querySelectorAll '.toolButton, .toolLabel, .toolIcon'
            if btn.name == name
                return btn
        
    setButtonIcon: (name, svg) -> @button(name).innerHTML = Exporter.loadSVG svg
    
    hideButton: (name) -> 
        
        if @button(name).firstChild.tagName == 'svg'
            @button(name).firstChild.style.display = 'none'
        else
            @button(name).style.color = 'transparent'
        
    showButton: (name, show) -> 
        
        if show? and not show then @hideButton name
        else 
            if @button(name).firstChild.tagName == 'svg'
                @button(name).firstChild.style.display = 'block'
            else
                @button(name).removeAttribute 'style' 

    toggleButton: (name) ->
        
        btn = @button name
        if btn.choice
            if !btn.toggle
                if active = $ btn.parentNode, '.active'
                    active.classList.remove 'active'
                    active.toggle = false
            else
                return
        
        btn.toggle = !btn.toggle
        btn.classList.toggle 'active'
    
    setToggle: (name, toggle=true) -> if @button(name).toggle != toggle then @toggleButton name
    getToggle: (name) -> @button(name).toggle
        
    # 0000000    000000000  000   000        0000000  000      000   0000000  000   000  
    # 000   000     000     0000  000       000       000      000  000       000  000   
    # 0000000       000     000 0 000       000       000      000  000       0000000    
    # 000   000     000     000  0000       000       000      000  000       000  000   
    # 0000000       000     000   000        0000000  0000000  000   0000000  000   000  
    
    onButtonClick: (event) => 
                
        button = event.target.name
        
        if not button?
            button = elemProp event.target, 'name'
        
        if button?
            @clickButton button, event 
            
        if not @hasParent()
            @kali.tools.collapseTemp()
            
        stopEvent event

    clickButton: (button, event) ->
        
        btn = @button button

        if btn.icon? and event?.shiftKey
            if event?.metaKey
                @kali.stage.addSVG Exporter.loadSVG btn.icon
                return

            if event?.ctrlKey
                svg = @kali.stage.copy()
                btn.innerHTML = svg
                @saveSVG btn.icon, svg
                return
                
        if btn.toggle?
            @toggleButton button
        
        btn.action?(event)    
        
    # 000000000  000  000000000  000      00000000  
    #    000     000     000     000      000       
    #    000     000     000     000      0000000   
    #    000     000     000     000      000       
    #    000     000     000     0000000  00000000  
    
    initTitle: (text) ->
        
        text ?= @constructor.name
        @title = @element.appendChild elem 'div', class:'title', text: text
            
    #  0000000  000   000   0000000   
    # 000       000   000  000        
    # 0000000    000 000   000  0000  
    #      000     000     000   000  
    # 0000000       0       0000000   
    
    setSVG: (svg) ->
        
        @element.innerHTML = svg
        @svg = SVG.adopt(@element.firstChild)
        @svg.addClass 'toolSVG'
        
    # 000   000   0000000   000   000  00000000  00000000     
    # 000   000  000   000  000   000  000       000   000    
    # 000000000  000   000   000 000   0000000   0000000      
    # 000   000  000   000     000     000       000   000    
    # 000   000   0000000       0      00000000  000   000    

    onMouseEnter: (event) =>

        return if event.buttons
        
        return if $(@element, '.toolHalo')?
                
        if @parent != @kali.tools.temp
            @kali.tools.collapseTemp()
            
        if @hasChildren() and not @childrenVisible()
            @kali.tools.temp = @
            if @cfg.popup == 'auto'
                @showChildren()
            else
                @element.addEventListener 'mousemove', @onMouseMove
                @element.addEventListener 'mousedown', @onMouseDown
                
    onMouseDown: (event) =>
        
        @popupTimeout = setTimeout @popupChildren, 100
        @element.addEventListener 'mouseup', @onMouseUp
        
    onMouseUp: (event) =>
        
        clearTimeout @popupTimeout
        
    popupChildren: => 
        
        @toggleChildren()
        delete @popupTimeout
        @keepChildren = true
                
    onMouseMove: (event) =>
        
        if event.buttons != 0
            @kali.tools.temp = @
            @showChildren()
            @element.removeEventListener 'mousemove', @onMouseMove

    onMouseLeave: => #log "onLeave #{@name}"
        
    #  0000000  000   000  000  000      0000000    00000000   00000000  000   000  
    # 000       000   000  000  000      000   000  000   000  000       0000  000  
    # 000       000000000  000  000      000   000  0000000    0000000   000 0 000  
    # 000       000   000  000  000      000   000  000   000  000       000  0000  
    #  0000000  000   000  000  0000000  0000000    000   000  00000000  000   000  

    initChildren: ->
        
        if @cfg.list?
            @children = []
            for child in @cfg.list
                tail = last(@children) ? @
                tool = @kali.tools.newTool child
                tool.parent = @
                if @cfg.orient == 'down'
                    tool.setPos x:tail.pos().x, y:tail.pos().y+@kali.toolSize/2
                else
                    tool.setPos x:tail.pos().x+@kali.toolSize, y:tail.pos().y
                @children.push tool
            @hideChildren()
    
    hasParent:   -> @parent? and @parent.name != 'tools'
    hasChildren: -> @children?.length > 0
    
    childrenVisible: -> @hasChildren() and first(@children).isVisible()
    toggleChildren:  -> if @childrenVisible() then @hideChildren() else @showChildren()
    
    showChildren: -> 
        
        @toFront()
        if @hasChildren()
            @addHalo()
            for c in @children
                c.show()
                
    hideChildren: -> 
        
        @delHalo()
        @toBack()
        if @hasChildren()
            for c in @children
                c.hide()

    toFront: (zIndex=100) ->
        
        @element.style.zIndex = zIndex
        if @children?.length
            for c in @children
                c.toFront zIndex+1

    toBack: ->
        
        @element.style.zIndex = 1
        
    delHalo: -> $('.toolHalo')?.remove()
    addHalo: (opt) -> 
        halo = elem class: 'toolHalo'
        halo.style.width      = "#{opt?.width ? ((@children.length+1)*66)}px"
        halo.style.left       = "#{not opt?.x? and 66 or opt.x}px"
        halo.style.top        = '-66px'
        halo.style.height     = "#{3*66}px"
        halo.style.background = 'rgba(0,0,0,0)'
        halo.style.position   = 'absolute'
        halo.style.zIndex     = 0
        @element.insertBefore halo, @element.firstChild
                
    #  0000000  000   000   0000000   00000000   
    # 000       000 0 000  000   000  000   000  
    # 0000000   000000000  000000000  00000000   
    #      000  000   000  000   000  000        
    # 0000000   00     00  000   000  000        
    
    swapParent: ->
        
        prt = @parent
        top = prt.parent
        @children = prt.children
        _.pull @children, @
        @children.unshift prt
        for c in @children
            c.parent = @
            
        @setPos prt.pos()
        for c in @children
            c.setPos @pos().plus pos 66*(1+@children.indexOf c), 0
        
        delete prt.children
        @parent = top
        _.pull top.children, prt
        top.children.push @
        delete @kali.tools.temp
        @hideChildren()
        if @parent.isVisible() and @parent.childrenVisible()
            @show()
            
        @kali.tools.store()
                
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    dragStart: (d,e) => @element.addEventListener    'mouseup', @onClick
    dragStop:  (d,e) => @element.removeEventListener 'mouseup', @onClick
    dragMove:  (d,e) => @element.removeEventListener 'mouseup', @onClick
            
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (event) => 
        
        if @svg? and event?.shiftKey
            if event?.metaKey
                @kali.stage.addSVG @svg.svg()
                return
                
            if event?.ctrlKey
                svg = @kali.stage.copy()
                @setSVG svg
                @saveSVG @name, svg
                return
            
        # log "click #{@name} keepChildren #{@keepChildren} parent #{@hasParent()} popup #{@cfg.popup}"
                
        if @hasChildren() and event
            if not @childrenVisible()
                if not @cfg.popup?
                    @toggleChildren()
                else if @name == @kali.shapeTool()
                    @toggleChildren()
            else if not @keepChildren
                @hideChildren()
        else if @hasParent()
            @swapParent()
            
        delete @keepChildren
            
        @execute()
        
    execute: ->

        if @group?
            post.emit 'tool', 'activate', @name
        else if @action?
            post.emit 'tool', @action, @name
        # else if @name not in ['tools', 'font', 'layer']
            # log "no action and no group #{@name}"
    
    activate:      -> @setActive true
    deactivate:    -> @setActive false
    setActive: (a) -> 
        @active = a
        @element.classList.toggle 'active', @active 
        
    pos:        -> pos parseInt(@element.style.left), parseInt(@element.style.top)
    setPos: (p) -> @element.style.left = "#{p.x}px"; @element.style.top = "#{p.y}px"
        
    # 000000000   0000000    0000000    0000000   000      00000000  
    #    000     000   000  000        000        000      000       
    #    000     000   000  000  0000  000  0000  000      0000000   
    #    000     000   000  000   000  000   000  000      000       
    #    000      0000000    0000000    0000000   0000000  00000000  
    
    show:    => @element.style.display = 'block'
    hide:    => @element.style.display = 'none'
    isVisible: => @element.style.display != 'none'
    toggleVisible: => if @isVisible() then @hide() else @show()

    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    getActive: (group) ->
        
        if @group == group and @active
            return @
        if @hasChildren()
            for tool in @children
                if a = tool.getActive group
                    return a

    getTool: (name) ->
        
        if @name == name
            return @
        if @hasChildren()
            for tool in @children
                if t = tool.getTool name
                    return t
                                        
module.exports = Tool

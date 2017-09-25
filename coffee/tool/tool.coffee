
# 000000000   0000000    0000000   000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000      0000000    0000000   0000000

{ fileExists, stopEvent, elem, drag, post, first, last, log, fs, _ } = require 'kxk'

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
                btn.classList.add 'toolToggle'
                btn.toggle = button.toggle
                btn.classList.toggle 'active', btn.toggle
                
            if button.icon? or button.tiny?
                btn.innerHTML = Exporter.loadSVG button.icon ? button.tiny
                btn.classList.add 'toolIcon'
                btn.classList.add 'toolTiny' if button.tiny?
                btn.classList.remove 'toolButton'
                btn.firstChild.classList.add 'toolIconSVG'
                btn.icon = button.icon ? button.tiny
                
            btn.addEventListener 'mousedown', (event) => 
                
                button = event.target.name
                
                if not button?
                    button = elemProp event.target, 'name'
                
                if button?
                    @clickButton button 
                    
                if not @hasParent()
                    @kali.tools.collapseTemp()
                    
                stopEvent event
                
            span.appendChild btn
            
        @element.appendChild span
     
    button: (name) ->
        
        for btn in @element.querySelectorAll '.toolButton, .toolLabel, .toolIcon'
            if btn.name == name
                return btn
                
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
        
        if @parent != @kali.tools.temp
            @kali.tools.collapseTemp()
            
        if @hasChildren() and not @childrenVisible()
            @kali.tools.temp = @
            @showChildren()

    onMouseLeave: =>
        
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
    
    childrenVisible: -> @hasChildren() and first(@children).visible()
    toggleChildren:  -> if @childrenVisible() then @hideChildren() else @showChildren()
    
    showChildren: -> 
        
        @toFront()
        if @hasChildren()
            for c in @children
                c.show()
                
    hideChildren: -> 
        
        @toBack()
        if @hasChildren()
            for c in @children
                c.hide()

    toFront: ->
        
        @element.style.zIndex = 100
        if @children?.length
            for c in @children
                c.toFront()

    toBack: ->
        
        @element.style.zIndex = 1
                
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
        @children.push prt
        for c in @children
            c.parent = @
        p = @pos()
        @setPos prt.pos()
        prt.setPos p
        delete prt.children
        @parent = top
        _.pull top.children, prt
        top.children.push @
        delete @kali.tools.temp
        @hideChildren()
        if @parent.visible() and @parent.childrenVisible()
            @show()
                
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

    clickButton: (button) ->
        
        btn = @button button

        if not btn?
            log 'wtf?', button
        
        if btn.icon?
            if event?.metaKey
                @kali.stage.addSVG Exporter.loadSVG btn.icon
                return

            if event?.ctrlKey
                svg = @kali.stage.copy()
                btn.innerHTML = svg
                @saveSVG btn.icon, svg
                return
                
        if btn.toggle?
            btn.toggle = !btn.toggle
            btn.classList.toggle 'active'
        
        btn.action?()    
    
    onClick: (event) => 
        
        if @svg?
            if event?.metaKey
                @kali.stage.addSVG @svg.svg()
                return
                
            if event?.ctrlKey
                svg = @kali.stage.copy()
                @setSVG svg
                @saveSVG @name, svg
                return
            
        if @hasChildren() and event
            @toggleChildren()
        else if @hasParent()
            if @cfg.orient != 'down'
                @swapParent()
        else 
            @hideChildren()
            
        @execute()
        
    execute: ->

        if @group?
            post.emit 'tool', 'activate', @name
        else if @action?
            post.emit 'tool', @action, @name
        else if @name not in ['tools', 'font', 'layer']
            log "no action and no group #{@name}"
    
    activate:      -> @setActive true
    deactivate:    -> @setActive false
    setActive: (a) -> 
        @active = a
        @element.classList.toggle 'active', @active 
        
    pos:        -> x:parseInt(@element.style.left), y:parseInt(@element.style.top)
    setPos: (p) -> @element.style.left = "#{p.x}px"; @element.style.top = "#{p.y}px"
        
    # 000000000   0000000    0000000    0000000   000      00000000  
    #    000     000   000  000        000        000      000       
    #    000     000   000  000  0000  000  0000  000      0000000   
    #    000     000   000  000   000  000   000  000      000       
    #    000      0000000    0000000    0000000   0000000  00000000  
    
    show:    => @element.style.display = 'block'; @element.style.zIndex = 100
    hide:    => @element.style.display = 'none'
    visible: => @element.style.display != 'none'
    toggleVisible: => if @visible() then @hide() else @show()

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

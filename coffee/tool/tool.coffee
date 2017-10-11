
# 000000000   0000000    0000000   000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000      0000000    0000000   0000000

{ fileExists, upElem, downElem, stopEvent, elem, drag, post, first, last, fs, pos, log, $, _ } = require 'kxk'

{ boundingBox } = require '../utils'

{ multi } = require 'heterarchy'

Spin     = require './spin'
Button   = require './button'
Exporter = require '../exporter'

class Tool extends multi Spin, Button

    constructor: (@kali, @cfg) ->

        super @kali
        
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
        @svg
        
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
        
        @updateDepth()
        if @hasChildren()
            @addHalo()
            for c in @children
                c.show()
        @updateDepth()
                
    hideChildren: -> 
        
        @delHalo()
        @element.style.zIndex = 1
        if @hasChildren()
            for c in @children
                c.hide()

    delHalo: -> $('.toolHalo')?.remove()
    addHalo: -> 

        halo = elem class: 'toolHalo'
        halo.style.width      = "#{@cfg.halo?.width  ? ((@children.length+1)*66)}px"
        halo.style.height     = "#{@cfg.halo?.height ? 3*66}px"
        halo.style.left       = "#{not @cfg.halo?.x? and  66 or @cfg.halo.x}px"
        halo.style.top        = "#{not @cfg.halo?.y? and -66 or @cfg.halo.y}px"
        halo.style.background = 'rgba(0,0,0,0.0)'
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
          
        @updateDepth()
            
        @kali.tools.store()
        
    updateDepth: ->
        
        return if @name == 'tools'
        
        zIndex = parseInt @element.style.zIndex
        for child in @children
            child.element.style.zIndex = parseInt zIndex + 1 + @children.indexOf child
                
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    dragStart: (d,e) => @element.addEventListener     'mouseup', @onClick
    dragStop:  (d,e) => @element?.removeEventListener 'mouseup', @onClick
    dragMove:  (d,e) => @element?.removeEventListener 'mouseup', @onClick
            
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (event) => 
        
        if @svg? and event?
            
            if event?.metaKey
                @kali.stage.addSVG @svg.svg()
                return
                
            if event?.ctrlKey
                svg = @kali.stage.copy()
                @setSVG svg
                Exporter.saveSVG @name, @svg
                return
            
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
        null

    getTool: (name) ->
        
        if @name == name
            return @
        if @hasChildren()
            for tool in @children
                if t = tool.getTool name
                    return t
                                        
module.exports = Tool

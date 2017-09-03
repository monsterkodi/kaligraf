
# 000000000   0000000    0000000   000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000      0000000    0000000   0000000

{ elem, drag, post, first, last, log, _ } = require 'kxk'

class Tool

    constructor: (@kali, @cfg) ->

        @name   = @cfg.name
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
            @element.appendChild elem 'div', class: 'title', text: _.capitalize @cfg.name
        
        @drag = new drag
            handle:  @element
            target:  @element
            onStart: @dragStart
            onMove:  @dragMove
            onStop:  @dragStop
         
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

    onMouseEnter: =>

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
                    tool.setPos x:tail.pos().x, y:tail.pos().y+30
                else
                    tool.setPos x:tail.pos().x+60, y:tail.pos().y
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
    dragMove:  (d,e) =>
        
        @element.removeEventListener 'mouseup', @onClick
        if e.metaKey and @hasChildren()
            @moveBy d.delta
            
    moveBy: (delta) -> 
        
        @setPos x:@pos().x+delta.x, y:@pos().y+delta.y
        if @hasChildren()
            for c in @children
                c.moveBy delta
        
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (e) => 
        
        if e?.metaKey and @svg?
            @kali.stage.addSVG @svg.svg()
            return
        if @hasChildren() and e
            @toggleChildren()
        else if @hasParent()
            @swapParent()
        else 
            @hideChildren()
            
        @execute()
        
    execute: ->
        
        if @group?
            post.emit 'tool', 'activate', @name
        else if @action?
            post.emit 'tool', @action, @name
        else
            post.emit 'tool', 'click', @name
    
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
    
    show:    => @element.style.display = 'block'
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

    minusPlus: (minusCB, plusCB) ->
        plus  = elem 'span', class:'toolPlus',  text:'+'
        minus = elem 'span', class:'toolMinus', text:'-'               
        
        plus .addEventListener 'mousedown', plusCB
        minus.addEventListener 'mousedown', minusCB
        
        plusMinus = elem 'div', class:'toolPlusMinus'
        plusMinus.appendChild minus
        plusMinus.appendChild plus
        @element.appendChild plusMinus
        
                    
module.exports = Tool

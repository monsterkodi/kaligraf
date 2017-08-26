
# 000000000   0000000    0000000   000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000      0000000    0000000   0000000

{ elem, drag, post, log } = require 'kxk'

class Tool

    constructor: (@kali, @cfg) ->

        @name   = @cfg.name
        @group  = @cfg.group
        @action = @cfg.action
        @active = false
        @parent = @kali.element
        
        @element = elem 'div', class: @name
        @element.classList.add 'tool'
        @parent.appendChild @element

        if @cfg.text?
            @element.appendChild elem 'span', text: @cfg.text
        
        @drag = new drag
            handle:  @element
            target:  @element
            onStart: @dragStart
            onMove:  @dragMove
            onStop:  @dragStop

    dragStart: (d,e) => @element.addEventListener    'mouseup', @onClick
    dragStop:  (d,e) => @element.removeEventListener 'mouseup', @onClick
    dragMove:  (d,e) =>
        
        @element.removeEventListener 'mouseup', @onClick
        if e.metaKey then @moveBy d.delta
            
    moveBy: (delta) -> @setPos x:@pos().x+delta.x, y:@pos().y+delta.y
        
    onClick: (e) => 
        
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
    
    toggleDisplay: =>
        
        if @element.style.display == 'none'
            @element.style.display = 'initial'
        else
            @element.style.display = 'none'
    
module.exports = Tool

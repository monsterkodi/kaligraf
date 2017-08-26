
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
            onMove:  (d,e) =>
                if e.metaKey
                    @dragMove d,e
                    @setPos x:@pos().x+d.delta.x, y:@pos().y+d.delta.y
            onStop: @dragStop

        post.on 'toggle', (msg) => if msg == @name then @toggleDisplay()
         
    dragStart: (d,e) => @element.addEventListener    'mouseup', @onClick
    dragMove:  (d,e) => @element.removeEventListener 'mouseup', @onClick
    dragStop:  (d,e) => @element.removeEventListener 'mouseup', @onClick
    onClick:     (e) => 
        if @group?
            post.emit 'tool', 'activate', @name
    
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

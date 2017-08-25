
# 000000000   0000000    0000000   000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000     000   000  000   000  000    
#    000      0000000    0000000   0000000

{ elem, drag, post } = require 'kxk'

class Tool

    constructor: (cfg) ->

        @name  = cfg.name
        parent = cfg.parent
        
        @element = elem 'div', class: @name
        parent.appendChild @element

        @drag = new drag
            handle: @element
            target: @element
            onStart: @dragStart
            onMove:  (e) => 
                @dragMove e
                @element.style.left = "#{@element.offsetLeft+e.delta.x}px"
                @element.style.top  = "#{@element.offsetTop+e.delta.y}px"

        post.on 'toggle', (msg) => if msg == @name then @toggleDisplay()
         
    dragStart: (e) => @element.addEventListener    'mouseup', @onClick
    dragMove:  (e) => @element.removeEventListener 'mouseup', @onClick
        
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


# 00     00  00000000  000   000  000   000  
# 000   000  000       0000  000  000   000  
# 000000000  0000000   000 0 000  000   000  
# 000 0 000  000       000  0000  000   000  
# 000   000  00000000  000   000   0000000   

{log, elem} = require 'kxk'
events = require 'events'

class Button extends events
    
    constructor: (@parent, data) -> @init data
    
    init: (data) ->
        
        @element = elem 'button', class: 'button'
        @element.innerHTML = data.button
        @element.name = data.button
        @element.addEventListener 'click', => data.click @
        @parent.element.appendChild @element

class Menu extends events

    constructor: (@parent, data) -> @init data
        
    init: (data) ->
        
        @element  = elem 'menu', class: 'menu'
        @children = []
        
        for d in data
            if d.button?
                @children.push new Button @, d
            
        @parent.element.appendChild @element
        
module.exports = Menu

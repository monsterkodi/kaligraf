
# 00     00  00000000  000   000  000   000
# 000   000  000       0000  000  000   000
# 000000000  0000000   000 0 000  000   000
# 000 0 000  000       000  0000  000   000
# 000   000  00000000  000   000   0000000

{ elem, post, log, _ } = require 'kxk'

class Button

    constructor: (@parent, @cfg) ->

        @element = elem 'div', class: 'item'
        @element.innerHTML = _.capitalize @cfg.name
        @parent.element.appendChild @element
        @element.addEventListener 'click', => log 'click'

class Menu

    constructor: (@kali, @parent, buttons) ->

        @children = []
        
        if not @parent?
            
            @element  = elem 'div', class: 'menus'
            @kali.element.appendChild @element
            
            @init()
            
        else
            
            @element  = elem 'div', class: 'menu'
            @parent.element.appendChild @element
            
            @element.addEventListener 'mouseenter', => 
                @element.style.overflow = 'visible'
            @element.addEventListener 'mouseleave', =>            
                @element.style.overflow = 'hidden'
            
            for button in buttons
                @children.push new Button @, button

    init: () ->

        menus = [
            [
                { name: 'save',   action: 'save',      combo: 'command+s' }
                { name: 'load',   action: 'load',      combo: 'command+o' }
                { name: 'clear',  action: 'clear',     combo: 'command+k' }
            ]
            [
                { name: 'center', action: 'center',    combo: 'command+e' }
                { name: 'all',    action: 'selectAll', combo: 'command+a' }
                { name: 'none',   action: 'deselect',  combo: 'command+d' }
            ]
            [
                { name: 'cut',    action: 'cut',       combo: 'command+x' }
                { name: 'copy',   action: 'copy',      combo: 'command+c' }
                { name: 'paste',  action: 'paste',     combo: 'command+v' }
            ]
            [
                { name: 'front',  action: 'front',     combo: 'command+alt+up'   }
                { name: 'raise',  action: 'raise',     combo: 'command+up'       }
                { name: 'lower',  action: 'lower',     combo: 'command+down'     }
                { name: 'back',   action: 'back',      combo: 'command+alt+down' }
            ]
        ]

        for menu in menus
            @children.push new Menu @kali, @, menu

module.exports = Menu

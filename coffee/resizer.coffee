
# 00000000   00000000   0000000  000  0000000  00000000  00000000 
# 000   000  000       000       000     000   000       000   000
# 0000000    0000000   0000000   000    000    0000000   0000000  
# 000   000  000            000  000   000     000       000   000
# 000   000  00000000  0000000   000  0000000  00000000  000   000

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

class Resizer

    constructor: (@kali) ->

        @element = elem 'div', id: 'resizer'
        @kali.element.appendChild @element
        @svg = SVG(@element).size '100%', '100%' 
        @svg.style
            'stroke-linecap': 'round'
            'stroke-linejoin': 'round'
        @svg.clear()
        
        post.on 'selection', @onSelection
        
    #  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000  
    # 000       000       000      000       000          000     000  000   000  0000  000  
    # 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000  
    #      000  000       000      000       000          000     000  000   000  000  0000  
    # 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000  
    
    onSelection: (action, item) ->
        
        switch action
            when 'add'   then log 'Resizer selection add'
            when 'del'   then log 'Resizer selection del'
            when 'clear' then if item then log 'Resizer selection clear'

module.exports = Resizer


#  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
# 000       000       000      000       000          000     000  000   000  0000  000
# 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
#      000  000       000      000       000          000     000  000   000  000  0000
# 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

{ log } = require 'kxk'

class Selection

    constructor: (@kali) ->
        
        @selected = []
       
    empty: -> @selected.length <= 0
    
    handleKey: (mod, key, combo, char, event) ->
        
        if not @empty()
            switch key
                when 'backspace'
                    for e in @selected
                        e.selectize false
                        e.remove()
                    @selected = []
                    return
                when 'left', 'right', 'up', 'down'
                    for e in @selected
                        x = y = 0
                        switch key
                            when 'left'  then x = -1
                            when 'right' then x =  1
                            when 'up'    then y = -1
                            when 'down'  then y =  1
                        e.dmove x, y
                
        'unhandled'
        
    add: (e) -> 
        if e not in @selected
            e.selectize deepSelect: true
            e.resize snapToAngle: 15
            @selected.push e

    clear: () ->
        for s in @selected
            s.selectize false, deepSelect: true
            s.resize 'stop'
        @selected = []
        
    moveBy: (delta) ->
        
        for s in @selected
            s.dmove delta.x, delta.y
        
module.exports = Selection

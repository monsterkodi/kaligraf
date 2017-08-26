
#  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
# 000       000       000      000       000          000     000  000   000  0000  000
# 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
#      000  000       000      000       000          000     000  000   000  000  0000
# 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

{ last, pos, elem, log, _ } = require 'kxk'

class Selection

    constructor: (@kali) ->
        
        @selected = []
      
    start: (p) -> @rect = start: p, end: p; @updateRect()
    move: (p) -> @rect.end = p; @updateRect()
    end: (p) -> @rect.element.remove(); delete @rect
    
    updateRect: ->
        if not @rect.element
            @rect.element = elem 'div', class: 'selectangle'
            @kali.element.appendChild @rect.element
        @rect.element.style.left   = "#{@rect.start.x}px"
        @rect.element.style.top    = "#{@rect.start.y}px"
        @rect.element.style.width  = "#{@rect.end.x - @rect.start.x}px"
        @rect.element.style.height = "#{@rect.end.y - @rect.start.y}px"
        
        log "rect", @rect.start, @rect.end
        
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
            
    del: (e) ->
        e.selectize false, deepSelect: true
        e.resize 'stop'
        _.pull @selected, e
    
    clear: () ->
        
        while not @empty()
            @del last @selected
        
    moveBy: (delta) ->
        
        for s in @selected
            s.dmove delta.x, delta.y

    contains: (e) -> e in @selected
            
module.exports = Selection

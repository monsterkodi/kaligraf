
#  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
# 000       000       000      000       000          000     000  000   000  0000  000
# 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
#      000  000       000      000       000          000     000  000   000  000  0000
# 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

{ last, pos, elem, log, _ } = require 'kxk'

class Selection

    constructor: (@kali) ->
        
        @selected = []

    #  0000000  00000000  000      00000000   0000000  000000000  00000000  0000000    
    # 000       000       000      000       000          000     000       000   000  
    # 0000000   0000000   000      0000000   000          000     0000000   000   000  
    #      000  000       000      000       000          000     000       000   000  
    # 0000000   00000000  0000000  00000000   0000000     000     00000000  0000000    
    
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
        
    empty: -> @selected.length <= 0
    contains: (e) -> e in @selected
        
    # 00000000   00000000   0000000  000000000    
    # 000   000  000       000          000       
    # 0000000    0000000   000          000       
    # 000   000  000       000          000       
    # 000   000  00000000   0000000     000       
      
    start: (p) -> @rect = x:p.x, y:p.y, x2: p.x, y2:p.y; @updateRect()
    move: (p) -> @rect.x2 = p.x; @rect.y2 = p.y; @updateRect()
    end: (p) -> @rect.element.remove(); delete @rect

    addRect: ->
        rect = elem 'div', class: 'selectangle'
        @kali.element.appendChild rect
        rect
            
    setRect: (elem, rect) ->
        [sx, ex] = [rect.x, rect.x2]
        [sy, ey] = [rect.y, rect.y2]
        if sx > ex then [sx, ex] = [ex, sx]
        if sy > ey then [sy, ey] = [ey, sy]
        elem.style.left   = "#{sx}px"
        elem.style.top    = "#{sy}px"
        elem.style.width  = "#{ex - sx}px"
        elem.style.height = "#{ey - sy}px"

    updateRect: ->
        
        if not @rect.element
            @rect.element = @addRect()
        @setRect @rect.element, @rect
        
        log 'stage: ', sb = @kali.stage.svg.rbox()
        for child in @kali.stage.svg.children()
            bb = child.rbox()
            bb.x  -= sb.x
            bb.x2 -= sb.x
            bb.y  -= sb.y
            bb.y2 -= sb.y
            @setRect @addRect(), bb
            
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
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
                        @moveElement e, x, y
                
        'unhandled'
        
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveBy: (delta) ->
        
        for s in @selected
            @moveElement s, delta.x, delta.y

    moveElement: (e, dx, dy) ->
        t = e.transform()
        e.transform x:t.x+dx, y:t.y+dy
            
module.exports = Selection

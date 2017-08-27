
#  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
# 000       000       000      000       000          000     000  000   000  0000  000
# 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
#      000  000       000      000       000          000     000  000   000  000  0000
# 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

{ last, pos, elem, post, log, _ } = require 'kxk'

class Selection

    constructor: (@kali) ->
        
        @selected = []
        
        post.on 'color', @onColor

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
        r = @offsetRect @normRect rect
        elem.style.left   = "#{r.x}px"
        elem.style.top    = "#{r.y}px"
        elem.style.width  = "#{r.x2 - r.x}px"
        elem.style.height = "#{r.y2 - r.y}px"
        
    updateRect: ->
        
        if not @rect.element
            @rect.element = @addRect()
        @setRect @rect.element, @rect        
        @selectInRect @rect
        
    selectInRect: (rect) ->
        r = @normRect rect
        for child in @kali.stage.svg.children()
            if child.id().startsWith 'SvgjsG'
                continue
            rb = child.rbox()
            if @intersect r, rb
                @add child

    intersect: (a, b) ->
        if a.x2 < b.x then return false
        if a.y2 < b.y then return false
        if b.x2 < a.x then return false
        if b.y2 < a.y then return false
        true
        
    normRect: (r) ->
        [sx, ex] = [r.x, r.x2]
        [sy, ey] = [r.y, r.y2]
        if sx > ex then [sx, ex] = [ex, sx]
        if sy > ey then [sy, ey] = [ey, sy] 
        x:sx, y:sy, x2:ex, y2:ey
        
    offsetRect: (r) ->
        s = @kali.stage.element.getBoundingClientRect()
        x = s.left
        y = s.top
        x:r.x-x, x2:r.x2-x, y:r.y-y, y2:r.y2-y
            
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event) ->
        
        if not @empty()
            switch key
                when 'backspace'
                    while not @empty()
                        l = last @selected
                        @del l
                        l.remove()
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
        dx /= @kali.stage.zoom()
        dy /= @kali.stage.zoom()
        t = e.transform()
        e.transform x:t.x+dx, y:t.y+dy
         
    #  0000000   0000000   000       0000000   00000000   
    # 000       000   000  000      000   000  000   000  
    # 000       000   000  000      000   000  0000000    
    # 000       000   000  000      000   000  000   000  
    #  0000000   0000000   0000000   0000000   000   000  
    
    pickColor: ->
        
        return if @empty()
        stroke = r:0, g:0, b:0
        fill   = r:0, g:0, b:0
        for s in @selected
            sc = new SVG.Color s.style 'stroke'
            fc = new SVG.Color s.style 'fill'
            for c in ['r', 'g', 'b']
                stroke[c] += sc[c]
                fill[c]   += fc[c]
        for c in ['r', 'g', 'b']                
            stroke[c] /= @selected.length
            fill[c]   /= @selected.length
           
        post.emit 'setColor', 'fill',   fill
        post.emit 'setColor', 'stroke', stroke
    
    onColor: (color, prop, value) =>
        
        return if @empty()
        
        attr = {}
        
        switch prop
            when 'alpha'
                attr[color + '-opacity'] = value
            when 'color'
                attr[color] = new SVG.Color value
                
        if not _.isEmpty attr
            for s in @selected
                s.style attr
            
module.exports = Selection

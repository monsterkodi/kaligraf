
#  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
# 000       000       000      000       000          000     000  000   000  0000  000
# 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
#      000  000       000      000       000          000     000  000   000  000  0000
# 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

{ last, pos, elem, post, log, _ } = require 'kxk'
{ normRect, rectsIntersect } = require './utils'

class Selection

    constructor: (@kali) ->
        
        @items = []
        
        post.on 'color', @onColor
        post.on 'line', @onLine

    # 0000000    00000000  000      00000000  000000000  00000000  
    # 000   000  000       000      000          000     000       
    # 000   000  0000000   000      0000000      000     0000000   
    # 000   000  000       000      000          000     000       
    # 0000000    00000000  0000000  00000000     000     00000000  
    
    delete: ->        
        while not @empty()
            l = last @items
            @del l
            l.remove()
        
    #  0000000  00000000  000      00000000   0000000  000000000  00000000  0000000    
    # 000       000       000      000       000          000     000       000   000  
    # 0000000   0000000   000      0000000   000          000     0000000   000   000  
    #      000  000       000      000       000          000     000       000   000  
    # 0000000   00000000  0000000  00000000   0000000     000     00000000  0000000    
    
    add: (e) ->
        
        if e not in @items
            # e.selectize()
            # e.resize snapToAngle: 15
            @items.push e
            post.emit 'selection', 'add', e
            
    del: (e) ->
        
        # e.selectize false
        # e.resize 'stop'
        
        if e in @items
            _.pull @items, e
            post.emit 'selection', 'del', e
    
    clear: () ->
        
        if not @empty()
            post.emit 'selection', 'clear', @items.length
            
        while not @empty()
            @del last @items
                    
    empty: -> @items.length <= 0
    contains: (e) -> e in @items
        
    # 00000000   00000000   0000000  000000000    
    # 000   000  000       000          000       
    # 0000000    0000000   000          000       
    # 000   000  000       000          000       
    # 000   000  00000000   0000000     000       
      
    start: (p,o) -> @rect = x:p.x, y:p.y, x2: p.x, y2:p.y; @updateRect o
    move: (p,o) -> @rect.x2 = p.x; @rect.y2 = p.y; @updateRect o
    end: (p) -> @rect.element.remove(); delete @rect

    addRect: (clss='selectangle')->
        
        rect = elem 'div', class: 'selectangle'
        @kali.element.appendChild rect
        rect
            
    setRect: (elem, rect) ->
        
        r = @offsetRect normRect rect
        elem.style.left   = "#{r.x}px"
        elem.style.top    = "#{r.y}px"
        elem.style.width  = "#{r.x2 - r.x}px"
        elem.style.height = "#{r.y2 - r.y}px"
        
    updateRect: (opt={}) ->
        
        if not @rect.element
            @rect.element = @addRect()
                            
        @setRect @rect.element, @rect        
        
        @selectInRect @rect, opt
        
    selectInRect: (rect, opt) ->
        
        r = normRect rect
        
        for child in @kali.stage.svg.children()

            if child.type != 'g' and child.id()?.startsWith 'SvgjsG'
                log 'skip', child
                continue

            rb = child.rbox()
            if rectsIntersect r, rb
                @add child
            else if not opt.join
                @del child
        
    offsetRect: (r) ->
        s = @kali.stage.element.getBoundingClientRect()
        x = s.left
        y = s.top
        x:r.x-x, x2:r.x2-x, y:r.y-y, y2:r.y2-y
                    
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveBy: (delta) ->
        
        for s in @items
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
        for s in @items
            sc = new SVG.Color s.style 'stroke'
            fc = new SVG.Color s.style 'fill'
            for c in ['r', 'g', 'b']
                stroke[c] += sc[c]
                fill[c]   += fc[c]
        for c in ['r', 'g', 'b']                
            stroke[c] /= @items.length
            fill[c]   /= @items.length
           
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
            for s in @items
                s.style attr
                
    onLine: (prop, value) =>
        
        return if @empty()
        
        for s in @items
            s.style switch prop
                when 'width' then 'stroke-width': value

    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event) ->
        
        if not @empty()
            switch combo
                when 'backspace', 'delete'
                    @delete()
                    return
                when 'left', 'right', 'up', 'down'
                    for e in @items
                        x = y = 0
                        switch key
                            when 'left'  then x = -1
                            when 'right' then x =  1
                            when 'up'    then y = -1
                            when 'down'  then y =  1
                        @moveElement e, x, y
        'unhandled'
                
module.exports = Selection

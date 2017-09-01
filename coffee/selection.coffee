
#  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
# 000       000       000      000       000          000     000  000   000  0000  000
# 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
#      000  000       000      000       000          000     000  000   000  000  0000
# 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

{ last, pos, elem, post, log, _ } = require 'kxk'

{ normRect, rectsIntersect, posForRect } = require './utils'

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

            if l.parent()?.removeElement?
                l.remove()
            else
                l.clear()
                l.node.remove()
        
    #  0000000  00000000  000      00000000   0000000  000000000  00000000  0000000    
    # 000       000       000      000       000          000     000       000   000  
    # 0000000   0000000   000      0000000   000          000     0000000   000   000  
    #      000  000       000      000       000          000     000       000   000  
    # 0000000   00000000  0000000  00000000   0000000     000     00000000  0000000    
    
    set: (items) ->
        
        @clear()
        @items = _.clone items
        
        log 'set', @items.length
        
        post.emit 'selection', 'set', @items
    
    add: (e) ->
        
        if e not in @items
            
            @items.push e
            
            # log 'add', @items.length, e.type
            
            post.emit 'selection', 'add', @items, e
            
    del: (e) ->
        
        if e in @items
            _.pull @items, e
            post.emit 'selection', 'del', @items, e
    
    clear: () ->

        if not @empty()
            @items = []
            post.emit 'selection', 'clear'
            
    empty: -> @items.length <= 0
    contains: (e) -> e in @items
        
    # 00000000   00000000   0000000  000000000    
    # 000   000  000       000          000       
    # 0000000    0000000   000          000       
    # 000   000  000       000          000       
    # 000   000  00000000   0000000     000       
      
    start: (p,o) -> @rect = x:p.x, y:p.y, x2: p.x, y2:p.y; @updateRect(o); log 'start'; @pos = posForRect @rect
    move: (p,o) -> @rect.x2 = p.x; @rect.y2 = p.y; delete @pos; @updateRect(o)
    end: (p) -> @rect.element.remove(); delete @rect; delete @pos

    addRect: (clss='selectionRect') ->
        
        rect = elem 'div', class: "selectangle #{clss}"
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
        
        for child in @kali.items()

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
        
        dx /= @kali.stage.zoom
        dy /= @kali.stage.zoom

        e.cx e.cx() + dx
        e.cy e.cy() + dy
         
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
    
    handleKey: (mod, key, combo, char, event, down) ->
        
        if not @empty() and down
            switch combo
                when 'backspace', 'delete'
                    return @delete()
                    
        'unhandled'
                
module.exports = Selection


#  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
# 000       000       000      000       000          000     000  000   000  0000  000
# 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
#      000  000       000      000       000          000     000  000   000  000  0000
# 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

{ last, elem, post, pos, log, _ } = require 'kxk'

{ normRect, rectsIntersect, rectOffset, boxForItems } = require './utils'

class Selection

    constructor: (@kali) ->
        
        @items = []
        
        @element = elem 'div', id: 'selection'
        @kali.element.appendChild @element
        
        @svg = SVG(@element).size '100%', '100%' 
        @svg.addClass 'selectionSVG'
        @svg.clear()

        @stage = @kali.stage
        
        post.on 'stage', @onStage
        
    # 0000000    00000000  000      00000000  000000000  00000000  
    # 000   000  000       000      000          000     000       
    # 000   000  0000000   000      0000000      000     0000000   
    # 000   000  000       000      000          000     000       
    # 0000000    00000000  0000000  00000000     000     00000000  
    
    delete: ->  
        
        if not @empty()
            for item in @items
                if item.parent()?.removeElement?
                    item.remove()
                else
                    item.clear()
                    item.node.remove()
        @clear()
        
    #  0000000  00000000  000      00000000   0000000  000000000  00000000  0000000    
    # 000       000       000      000       000          000     000       000   000  
    # 0000000   0000000   000      0000000   000          000     0000000   000   000  
    #      000  000       000      000       000          000     000       000   000  
    # 0000000   00000000  0000000  00000000   0000000     000     00000000  0000000    
    
    setItems: (items) ->
        
        @clear()
        @items = items ? []
        
        if @items.length

            for item in @items
                @addRectForItem item
        
        post.emit 'selection', 'set', @items
    
    addItem: (item) ->
        
        if item not in @items
            
            @items.push item
            @addRectForItem item
            
            post.emit 'selection', 'add', @items, item
            
    delItem: (item) ->
        
        if item in @items
            _.pull @items, item
            @delRectForItem item
            post.emit 'selection', 'del', @items, item
    
    clear: () ->

        if not @empty()
            for item in @items
                item.forget 'itemRect'
            @items = []
            @svg.clear()
            post.emit 'selection', 'clear'
            
    empty: -> @items.length <= 0
    contains: (item) -> item in @items

    # 000  000000000  00000000  00     00   0000000    
    # 000     000     000       000   000  000         
    # 000     000     0000000   000000000  0000000     
    # 000     000     000       000 0 000       000    
    # 000     000     00000000  000   000  0000000     
    
    addRectForItem: (item) ->

        r = @svg.rect()
        r.addClass 'resizerItemRect'
        item.remember 'itemRect', r
        @updateItemRect item, r

    delRectForItem: (item) ->
        
        if r = item.remember 'itemRect' 
            r.remove()
            item.forget 'itemRect'
        
    updateItems: ->

        for item in @items
            @updateItemRect item
        
    updateItemRect: (item, r) ->
        
        box = item.bbox()
        r = item.remember('itemRect') if not r?
        if r?
            r.attr
                x:      box.x
                y:      box.y
                width:  box.width
                height: box.height
            r.transform item.transform()

    onStage: (action, box) =>
        
        if action == 'viewbox' 
            @svg.viewbox box
    
    # 00000000   00000000   0000000  000000000    
    # 000   000  000       000          000       
    # 0000000    0000000   000          000       
    # 000   000  000       000          000       
    # 000   000  00000000   0000000     000       
      
    startRect: (p,o) -> 
        
        @rect = x:p.x, y:p.y, x2:p.x, y2:p.y 
        @pos = rectOffset @rect
        @updateRect o
        
    moveRect: (p,o) -> 
    
        @rect.x2 = p.x
        @rect.y2 = p.y
        delete @pos
        @updateRect o
        
    endRect: (p) -> 
    
        @rect.element.remove() 
        delete @pos
        delete @rect

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
                @addItem child
            else if not opt.join
                @delItem child
        
    offsetRect: (r) ->
        
        s = @kali.stage.element.getBoundingClientRect()
        x = s.left
        y = s.top
        x:r.x-x, x2:r.x2-x, y:r.y-y, y2:r.y2-y

    viewPos: -> r = @element.getBoundingClientRect(); pos r.left, r.top
            
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveBy: (delta) -> 
    
        @stage.moveItems @items, delta
        @updateItems()
         
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

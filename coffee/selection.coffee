
#  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
# 000       000       000      000       000          000     000  000   000  0000  000
# 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
#      000  000       000      000       000          000     000  000   000  000  0000
# 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

{ last, elem, post, pos, log, _ } = require 'kxk'

{   contrastColor, moveBox, scaleBox, boxOffset, boxForItems,
    normRect, rectsIntersect, rectOffset} = require './utils'

class Selection

    constructor: (@kali) ->
        
        @stage = @kali.stage
        @trans = @kali.trans
        
        @items = []
        
        @element = elem 'div', id: 'selection'
        @kali.insertBelowTools @element
        
        @rectsWhite = SVG(@element).size '100%', '100%' 
        @rectsWhite.addClass 'selectionWhite'
        @rectsWhite.clear()

        @rectsBlack = SVG(@element).size '100%', '100%' 
        @rectsBlack.addClass 'selectionBlack'
        @rectsBlack.clear()
        
        post.on 'stage', @onStage
       
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  
    
    state: -> ids: @items.map (item) -> item.id()
    
    restore: (state) ->
        log 'restore', state
        @setItems state.ids.map (id) -> SVG.get id
    
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
    
    addItem: (item, o = join:true) ->
        
        if not o.join then @clear()
            
        if item not in @items
            
            @items.push item
            @addRectForItem item
            
            post.emit 'selection', 'add', @items, item
            
    delItem: (item) ->
        
        if item in @items
            _.pull @items, item
            @delRectForItem item
            post.emit 'selection', 'del', @items, item
    
    clear: ->

        if not @empty()
            
            for item in @items
                item.forget 'itemRect'
                
            @items = []
            @rectsWhite.clear()
            @rectsBlack.clear()
            post.emit 'selection', 'clear'
            return true
            
        false
            
    empty: -> @items.length <= 0
    contains: (item) -> item in @items

    # 000  000000000  00000000  00     00   0000000    
    # 000     000     000       000   000  000         
    # 000     000     0000000   000000000  0000000     
    # 000     000     000       000 0 000       000    
    # 000     000     00000000  000   000  0000000     
    
    addRectForItem: (item) ->

        r = @rectsWhite.rect()
        item.remember 'itemRectWhite', r

        r = @rectsBlack.rect()
        item.remember 'itemRectBlack', r
        
        @updateItemRect item
        
    delRectForItem: (item) ->
        
        if r = item.remember 'itemRectWhite' 
            r.remove()
            item.forget 'itemRectWhite'

        if r = item.remember 'itemRectBlack' 
            r.remove()
            item.forget 'itemRectBlack'
            
    updateItems: ->

        for item in @items
            @updateItemRect item
        
    updateItemRect: (item) ->
        
        box = item.bbox()

        if r = item.remember 'itemRectWhite' 
            
            r.attr
                x:      box.x
                y:      box.y
                width:  box.width
                height: box.height
                
            r.transform item.transform()

        if r = item.remember 'itemRectBlack' 
            
            r.attr
                x:      box.x
                y:      box.y
                width:  box.width
                height: box.height
                
            r.transform item.transform()

    onStage: (action, box) =>
        
        if action == 'viewbox' 
            
            @rectsWhite.viewbox box
            @rectsBlack.viewbox box
            
            dashArray = "#{2/@stage.zoom},#{6/@stage.zoom}"
            
            @rectsWhite.style 'stroke-width': 1/@stage.zoom
            @rectsWhite.style 'stroke-dasharray': dashArray
            @rectsWhite.style 'stroke-dashoffset': "#{2/@stage.zoom}"

            @rectsBlack.style 'stroke-width': 1/@stage.zoom
            @rectsBlack.style 'stroke-dasharray': dashArray
            
            @updateRect()
            
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     

    stageStart: (drag, event) ->
        
        eventPos = pos event
        
        if item = @stage.itemAtPos eventPos
            if not @contains item
                @addItem item, join:event.shiftKey
            else # if not switched
                if event.shiftKey then @delItem item
        else
            @startRect eventPos, join:event.shiftKey
    
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveBy: (delta) ->
        
        @stage.moveItems @items, delta
        @updateItems()
            
    # 00000000   00000000   0000000  000000000    
    # 000   000  000       000          000       
    # 0000000    0000000   000          000       
    # 000   000  000       000          000       
    # 000   000  00000000   0000000     000       
      
    startRect: (p,o) -> 
        
        if not o.join then @clear()
        @rect = x:p.x, y:p.y, x2:p.x, y2:p.y 
        @updateRect o
        
    moveRect: (p,o) -> 
    
        @rect.x2 = p.x
        @rect.y2 = p.y
        @updateRect o
        
    endRect: (p) -> 
    
        @rect.element.remove() 
        delete @rect

    addRect: ->
        
        rect = elem 'div', class: 'selectionRect'
        ctra = contrastColor @stage.color
        rect.style.background = "rgba(#{ctra.r}, #{ctra.g}, #{ctra.b}, 0.1)"
        rect.style.borderColor = "rgba(#{ctra.r}, #{ctra.g}, #{ctra.b}, 0.3)"
        @kali.element.appendChild rect
        rect
            
    setRect: (elem, rect) ->
        
        r = @offsetRect normRect rect
        elem.style.left   = "#{r.x}px"
        elem.style.top    = "#{r.y}px"
        elem.style.width  = "#{r.x2 - r.x}px"
        elem.style.height = "#{r.y2 - r.y}px"
        
    updateRect: (opt={}) ->
        
        return if not @rect?
        
        if not @rect.element
            @rect.element = @addRect()
        
        @setRect @rect.element, @rect        
        
        @selectInRect @rect, opt
        
    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    selectInRect: (rect, opt) ->

        r = @stageRect normRect rect
        
        for child in @kali.items()

            rb = @trans.rect child
            
            if rectsIntersect r, rb
                
                @addItem child
                
            else if not opt.join
                
                @delItem child
        
    offsetRect: (r) ->
        
        s = @kali.stage.element.getBoundingClientRect()
        x = s.left
        y = s.top
        x:r.x-x, x2:r.x2-x, y:r.y-y, y2:r.y2-y

    stageRect: (r) ->
        
        moveBox scaleBox(@offsetRect(r), 1/@stage.zoom), boxOffset @stage.svg.viewbox()
        
    viewPos: -> r = @element.getBoundingClientRect(); pos r.left, r.top
        
    bbox: -> @rectsWhite.bbox()
    
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

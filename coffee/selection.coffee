###
 0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
000       000       000      000       000          000     000  000   000  0000  000
0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
     000  000       000      000       000          000     000  000   000  000  0000
0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000
###

{ post, prefs, setStyle, last, elem, pos, str, log, _ } = require 'kxk'

{   contrastColor, moveBox, scaleBox, boxOffset, bboxForItems,
    normRect, rectsIntersect, rectOffset, itemBox } = require './utils'

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
        
        @showIDs prefs.get 'stage:ids', false
        
        post.on 'stage', @onStage
       
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  
    
    state: -> ids: @items.map (item) -> item.id()
    
    restore: (state) ->

        items = state.ids.map (id) -> SVG.get id
        items = items.filter (item) -> item?
        @setItems items
            
    # 0000000    00000000  000      00000000  000000000  00000000  
    # 000   000  000       000      000          000     000       
    # 000   000  0000000   000      0000000      000     0000000   
    # 000   000  000       000      000          000     000       
    # 0000000    00000000  0000000  00000000     000     00000000  
    
    delete: ->  
        
        if not @empty()
            @stage.do()
            for item in @items
                if item.parent()?.removeElement?
                    item.remove()
                else
                    item.clear()
                    item.node.remove()
            @clear()
            @stage.done()
        
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
        
        @emitSet()

    emitSet: -> post.emit 'selection', 'set', @items
    
    addItem: (item, o = join:true) ->
        
        if not item
            log 'addItem null item?', item
            return
        if not o.join then @clear()
            
        if item not in @items
            
            @items.push item
            @addRectForItem item
            # post.emit 'selection', 'add', @items, item
            
    delItem: (item) ->
        
        if item in @items
            _.pull @items, item
            @delRectForItem item
            # post.emit 'selection', 'del', @items, item
    
    clear: ->

        if not @empty()
            
            for item in @items
                if not item?
                    log 'selection.clear wtf?'
                    continue 
                item.forget 'itemRectWhite'
                item.forget 'itemRectBlack'
                item.forget 'itemIDRect'
                item.forget 'itemID'
                
            @items = []
            @rectsWhite.clear()
            @rectsBlack.clear()
            @ids?.clear()
            post.emit 'selection', 'clear'
            return true
            
        false
      
    length: -> @items.length
    empty:  -> @items.length <= 0
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
            
        if id = item.remember 'itemID'
            id.remove()
            item.forget 'itemID'
            
        if idRect = item.remember 'itemIDRect'
            idRect.remove()
            item.forget 'itemIDRect'
            
    update: -> @updateItems()
            
    updateItems: (items=@items) ->

        for item in items
            @updateItemRect item
            
    updateItemRect: (item) ->
        
        box = itemBox item

        if r = item.remember 'itemRectWhite' 
            
            r.attr
                x:      box.x
                y:      box.y
                width:  Math.max 1, box.width
                height: Math.max 1, box.height
                
            r.transform item.transform()

        if r = item.remember 'itemRectBlack' 
            
            r.attr
                x:      box.x
                y:      box.y
                width:  Math.max 1, box.width
                height: Math.max 1, box.height
                
            r.transform item.transform()
            
        @updateItemID item
        
    # 000  000000000  00000000  00     00  000  0000000    
    # 000     000     000       000   000  000  000   000  
    # 000     000     0000000   000000000  000  000   000  
    # 000     000     000       000 0 000  000  000   000  
    # 000     000     00000000  000   000  000  0000000    
    
    showIDs: (show=true) -> 
    
        if show
            if not @ids?
                @ids = SVG(@element).size '100%', '100%'
                @ids.addClass 'selectionIDs'
                @element.insertBefore @ids.node, @rectsBlack.node.nextSibling
            @ids.clear()
            @updateIDs()
        else
            for item in @items
                item.forget 'itemIDRect'
                item.forget 'itemID'
            @ids?.remove()
            delete @ids

    updateIDs: ->

        @ids.viewbox @stage.svg.viewbox()
        @ids.style 'font-size',    12/@stage.zoom
        @ids.style 'font-family', 'Menlo,Monaco,Andale Mono,Arial,Verdana'
        @ids.style 'stroke-width', 1/@stage.zoom
        
        for item in @items
            @updateItemID item
            
    updateItemID: (item) ->
        
        if @ids
            
            box = itemBox item
            
            if not idRect = item.remember 'itemIDRect'    
                idRect = @ids.rect 0,0
                idRect.addClass 'itemIDRect'
                item.remember 'itemIDRect', idRect
                
            if not id = item.remember 'itemID'
                id = @ids.text item.id().slice 0,4
                id.addClass     'itemID'
                id.style font:  'inherit'
                item.remember   'itemID', id
    
            id.transform item.transform()

            idRect.attr x:box.x, y:box.y
            idRect.transform item.transform()
            @trans.width  idRect, @trans.width(id)+4
            @trans.height idRect, 14/@stage.zoom
            
            @trans.center id, @trans.center(idRect).plus 2
            
    #  0000000   000   000   0000000  000000000   0000000    0000000   00000000  
    # 000   000  0000  000  000          000     000   000  000        000       
    # 000   000  000 0 000  0000000      000     000000000  000  0000  0000000   
    # 000   000  000  0000       000     000     000   000  000   000  000       
    #  0000000   000   000  0000000      000     000   000   0000000   00000000  
    
    onStage: (action, box) =>
        
        if action == 'viewbox' 
            
            @rectsWhite.viewbox box
            @rectsBlack.viewbox box
            
            if @ids? then @updateIDs()
            
            dashArray = "#{2/@stage.zoom},#{6/@stage.zoom}"
            
            @rectsWhite.style 'stroke-width': 1/@stage.zoom
            @rectsWhite.style 'stroke-dasharray': dashArray
            @rectsWhite.style 'stroke-dashoffset': "#{2/@stage.zoom}"

            @rectsBlack.style 'stroke-width': 1/@stage.zoom
            @rectsBlack.style 'stroke-dasharray': dashArray
            
            @updateRect()
            
        if action == 'color'
            ctra = contrastColor @stage.color
            setStyle '.selectionRect', 'background',  "rgba(#{ctra.r}, #{ctra.g}, #{ctra.b}, 0.1)"
            setStyle '.selectionRect', 'borderColor', "rgba(#{ctra.r}, #{ctra.g}, #{ctra.b}, 0.3)"            
            setStyle '.paddingRect',   'borderColor', "rgba(#{ctra.r}, #{ctra.g}, #{ctra.b}, 0.3)"            
            
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     

    stageStart: (drag, event) ->
        
        if event.button != 0
            return 'skip'
        
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
    
    moveBy: (delta, event) ->
        
        delta = delta.times 1/@stage.zoom
        
        if event? 
            if not event.metaKey
                delta = @kali.tool('snap').delta delta, items:@items
            else
                @kali.tool('snap').clear()
            
        @stage.moveItemsBy @items, delta
        @update()
            
    # 00000000   00000000   0000000  000000000    
    # 000   000  000       000          000       
    # 0000000    0000000   000          000       
    # 000   000  000       000          000       
    # 000   000  00000000   0000000     000       
      
    startRect: (p,o) -> 

        if not o.join then @clear()
        @rect = @stage.offsetRect x:p.x, y:p.y, x2:p.x, y2:p.y 
        @updateRect o
        
    moveRect: (p,o) -> 
    
        vp = @stage.viewPos()
        @rect.x2 = p.x-vp.x
        @rect.y2 = p.y-vp.y
        @updateRect o
        
    endRect: (p) -> 
    
        @rect.element.remove() 
        delete @rect

    addRect: ->
        
        rect = elem 'div', class: 'selectionRect'
        @kali.insertAboveSelection rect         
        rect
            
    setRect: (elem, rect) ->
        if not elem?
            log 'dafuk?', elem, rect
            return 
        r = normRect rect
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
        
        for child in @stage.pickableItems()

            rb = @trans.rect child
             
            if rectsIntersect r, rb
                 
                @addItem child
                 
            else if not opt.join
                 
                @delItem child
        
    stageRect: (r) ->
        
        moveBox scaleBox(r, 1/@stage.zoom), boxOffset @stage.svg.viewbox()
        
    bbox: -> @rectsWhite.bbox()
        
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

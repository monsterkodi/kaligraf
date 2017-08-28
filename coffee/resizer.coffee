
# 00000000   00000000   0000000  000  0000000  00000000  00000000 
# 000   000  000       000       000     000   000       000   000
# 0000000    0000000   0000000   000    000    0000000   0000000  
# 000   000  000            000  000   000     000       000   000
# 000   000  00000000  0000000   000  0000000  00000000  000   000

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{ boxForItems, posForRect, moveBox } = require './utils'

class Resizer

    constructor: (@kali) ->

        @selection = @kali.stage.selection
        @element = elem 'div', id: 'resizer'
        @kali.element.appendChild @element
        @svg = SVG(@element).size '100%', '100%' 
        @svg.style
            'stroke-linecap': 'round'
            'stroke-linejoin': 'round'
        @svg.clear()
        
        @box   = null
        @rect  = null
        @itemRect = {}
        
        post.on 'selection', @onSelection
        post.on 'stage',     @onStage

    # 00000000   00000000   0000000  000000000  
    # 000   000  000       000          000     
    # 0000000    0000000   000          000     
    # 000   000  000       000          000     
    # 000   000  00000000   0000000     000     
    
    createRect: ->
        
        @rect = @svg.rect()
        @rect.style
            stroke: '#fff'
            fill:   'rgba(0,0,0,0.1)'
            cursor: '-webkit-grab'
            'pointer-events': 'all'
            
        @drag = new drag
            target:  @rect.node
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop
                    
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (drag, event) => 
        
        if event?.shiftKey
            @kali.stage.handleMouseDown event
            return 'skip'
    
    onDragStop:  => 
    
    onDragMove: (drag) => 
        
        if not @selection.rect? 
            @selection.moveBy drag.delta
            @moveBy drag.delta
            
    moveBy: (delta) ->
        
        @setBox moveBox @box, delta
        @updateItems()
        
    # 0000000     0000000   000   000  
    # 000   000  000   000   000 000   
    # 0000000    000   000    00000    
    # 000   000  000   000   000 000   
    # 0000000     0000000   000   000  
    
    setBox: (@box) ->
        
        @rect.attr 
            x:      @box.x-@viewPos().x
            y:      @box.y-@viewPos().y
            width:  @box.w
            height: @box.h
        
    #  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000  
    # 000       000       000      000       000          000     000  000   000  0000  000  
    # 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000  
    #      000  000       000      000       000          000     000  000   000  000  0000  
    # 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000  
    
    onSelection: (action, items, item) =>
        log 'onSelection action:', action, 'item:', item?.id()
        switch action
            when 'add'   then @addItem items, item
            when 'del'   then @delItem items, item
            when 'clear' then @clear()

    clear: ->
        
        @box = null
        @rect.remove()
        for id, ir of @itemRect
            ir.remove()
        @itemRect = {}

    addRectForItem: (item) ->
        
        @itemRect[item.id()] = r = @svg.rect()
        r.style
            fill: 'none'
            stroke: '#888'
            'stroke-dasharray': '2,2'
        @updateItem item

    updateItems: ->
        for item in @selection.items
            @updateItem item
        
    updateItem: (item) ->
        
        @setItemBox item, boxForItems [item], @viewPos()
        
    setItemBox: (item, box) ->
        
        r = @itemRect[item.id()]
        r.attr
            x:      box.x
            y:      box.y
            width:  box.w
            height: box.h
            
    addItem: (items, item) ->
        
        @addRectForItem item
        
        if items.length == 1
            @createRect()
            @setBox item.rbox()
        else
            @setBox @box.merge item.rbox()
            
        if @kali.stage.selection.pos
            @drag.start @kali.stage.selection.pos
        else
            log 'no pos?'
            
    delItem: (items, item) ->
        
        @itemRect[item.id()]?.remove()
        delete @itemRect[item.id()]
        
        if @box
            @setBox boxForItems items

    calcBox: ->
        
        selection = @kali.stage.selection
        if not selection.empty()
            @setBox boxForItems selection.items
            @updateItems()
            
    # 000   000  000  00000000  000   000  
    # 000   000  000  000       000 0 000  
    #  000 000   000  0000000   000000000  
    #    000     000  000       000   000  
    #     0      000  00000000  00     00  
    
    viewPos:  -> r = @element.getBoundingClientRect(); x:r.left, y:r.top
    viewSize: -> r = @element.getBoundingClientRect(); width:r.width, height:r.height
    
    onStage: (action, box) =>
        
        switch action
            when 'viewbox' then @calcBox()
    
module.exports = Resizer

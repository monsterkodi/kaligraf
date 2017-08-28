
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
        @svg.addClass 'resizerSVG'
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
        @rect.addClass 'resizerRect'
            
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
    
    onDragMove: (drag) => @moveBy drag.delta
            
    moveBy: (delta) ->
        
        if not @selection.rect?
            @selection.moveBy delta
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
        # log 'onSelection action:', action, 'item:', item?.id()
        switch action
            when 'add'   then @addItem items, item
            when 'del'   then @delItem items, item
            when 'clear' then @clear()

    empty: -> not @box
    clear: ->
        
        @box = null
        @rect.remove()
        for id, ir of @itemRect
            ir.remove()
        @itemRect = {}

    addRectForItem: (item) ->
        
        @itemRect[item.id()] = r = @svg.rect()
        r.addClass 'resizerItemRect'

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

    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event) ->
        
        if not @empty()
            switch combo
                when 'left', 'right', 'up', 'down'
                    p = pos 0, 0
                    switch key
                        when 'left'  then p.x = -1
                        when 'right' then p.x =  1
                        when 'up'    then p.y = -1
                        when 'down'  then p.y =  1
                    @moveBy p
                    
        'unhandled'
            
module.exports = Resizer

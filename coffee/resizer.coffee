
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
        
        @box  = null
        @rect = null
        
        @borderDrag = {}
        @cornerDrag = {}
        
        post.on 'selection', @onSelection
        post.on 'stage',     @onStage

    # 00000000   00000000   0000000  000000000  
    # 000   000  000       000          000     
    # 0000000    0000000   000          000     
    # 000   000  000       000          000     
    # 000   000  00000000   0000000     000     
    
    createRect: ->
        
        @g = @svg.nested()
        @g.addClass 'resizerGroup'
        
        @rect = @g.rect().addClass 'resizerRect'
        @rect.attr width: '100%', height: '100%'

        addBorder = (x, y, w, h, cursor, id) =>
            border = @g.rect().addClass 'resizerBorder'
            border.attr x:x, y:y, width:w, height:h
            border.style cursor: cursor
            @borderDrag[id] = new drag
                target:  border.node 
                onStart: @onBorderStart
                onMove:  @onBorderMove
                onStop:  @onBorderStop
            @borderDrag[id].id = id

        addBorder -5,     0, 5, '100%', 'ew-resize', 'left'
        addBorder '100%', 0, 5, '100%', 'ew-resize', 'right'
        addBorder 0,     -5, '100%', 5, 'ns-resize', 'top'
        addBorder 0, '100%', '100%', 5, 'ns-resize', 'bot'

        addCorner = (x, y, cursor, id) =>
            corner = @g.circle(10).addClass 'resizerCorner'
            corner.attr cx:x, cy:y
            corner.style cursor:cursor
            @cornerDrag[id] = new drag 
                target:  corner.node
                onStart: @onCornerStart
                onMove:  @onCornerMove
                onStop:  @onCornerStop
            @cornerDrag[id].id = id
                
        addCorner 0,           0, 'nw-resize', 'top left'
        addCorner '100%',      0, 'ne-resize', 'top right'
        addCorner 0,      '100%', 'sw-resize', 'bot left'
        addCorner '100%', '100%', 'se-resize', 'bot right'

        @drag = new drag
            target:  @rect.node
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop

    # 00000000   00000000   0000000  000  0000000  00000000    
    # 000   000  000       000       000     000   000         
    # 0000000    0000000   0000000   000    000    0000000     
    # 000   000  000            000  000   000     000         
    # 000   000  00000000  0000000   000  0000000  00000000    
    
    onCornerStart: (drag, event) => #log "corner #{drag.id} onStart"
    onCornerStop:  (drag, event) => #log "corner #{drag.id} onStop"
    onCornerMove:  (drag, event) => @onResizeMove drag, event

    onBorderStart: (drag, event) => #log "border #{drag.id} onStart"
    onBorderStop:  (drag, event) => #log "border #{drag.id} onStop"
    onBorderMove:  (drag, event) => @onResizeMove drag, event
        
    onResizeMove:  (drag, event) =>
        # log "border #{drag.id} onMove"
        
        left  = drag.id.includes 'left'
        right = drag.id.includes 'right'
        top   = drag.id.includes 'top'
        bot   = drag.id.includes 'bot'
        dx    = 0
        dy    = 0
        dx    = -drag.delta.x if left
        dx    =  drag.delta.x if right
        dy    = -drag.delta.y if top
        dy    =  drag.delta.y if bot

        fx = (@box.w + dx)/@box.w
        fy = (@box.h + dy)/@box.h

        for item in @selection.items
            if item.type in ['circle', 'ellipse']
                iw = item.width()
                ih = item.height()
            else
                if right then item.x @box.x + fx * (item.x() - @box.x) 
                if bot   then item.y @box.y + fy * (item.y() - @box.y)
                if left  then item.x @box.x2 - fx * (@box.x2 - item.x())
                if top   then item.y @box.y2 - fy * (@box.y2 - item.y())
                            
            if item.type in ['circle']
                if Math.abs(dx) > Math.abs(dy)
                    f = fx
                else if Math.abs(dy) > Math.abs(dx)
                    f = fy
                else
                    f = 1
                item.radius (item.width() * f)/2.0
            else
                item.size item.width() * fx, item.height() * fy
                
            if item.type in ['circle']
                if right then item.cx item.width()/2  + @box.x  + f * ((item.cx() - iw/2) - @box.x)
                if bot   then item.cy item.height()/2 + @box.y  + f * ((item.cy() - ih/2) - @box.y) 
                if left  then item.cx item.width()/2  + @box.x2 - f * (@box.x2 - (item.cx() - iw/2))
                if top   then item.cy item.height()/2 + @box.y2 - f * (@box.y2 - (item.cy() - ih/2))
            else if item.type in ['ellipse']
                if right then item.cx item.width()/2  + @box.x  + fx * ((item.cx() - iw/2) - @box.x)
                if bot   then item.cy item.height()/2 + @box.y  + fy * ((item.cy() - ih/2) - @box.y) 
                if left  then item.cx item.width()/2  + @box.x2 - fx * (@box.x2 - (item.cx() - iw/2))
                if top   then item.cy item.height()/2 + @box.y2 - fy * (@box.y2 - (item.cy() - ih/2))
                                                        
        @calcBox()         
        
                
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (drag, event) => 
        
        if event?.shiftKey
            @kali.stage.handleMouseDown event
            return 'skip'
    
    onDragStop: => 
    
    onDragMove: (drag) => @moveBy drag.delta
            
    moveBy: (delta) ->
        
        if not @selection.rect?
            @selection.moveBy delta
            @calcBox()
        
    # 0000000     0000000   000   000  
    # 000   000  000   000   000 000   
    # 0000000    000   000    00000    
    # 000   000  000   000   000 000   
    # 0000000     0000000   000   000  
    
    setBox: (@rbox) ->
        
        @box = new SVG.RBox @rbox
        @box.x  -= @viewPos().x
        @box.y  -= @viewPos().y
        @box.cx -= @viewPos().x
        @box.cy -= @viewPos().y
        @box.x2 -= @viewPos().x
        @box.y2 -= @viewPos().y
        
        # log @box
        
        @g.attr 
            x:      @box.x
            y:      @box.y
            width:  @box.w
            height: @box.h

    calcBox: ->
        
        if not @selection.empty()
            @setBox boxForItems @selection.items
            @updateItems()
            
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
        @svg.clear()
        
        for k,d of @borderDrag
            d.deactivate()
        @borderDrag = {}

        for k,d of @cornerDrag
            d.deactivate()
        @cornerDrag = {}
        
    # 000  000000000  00000000  00     00   0000000  
    # 000     000     000       000   000  000       
    # 000     000     0000000   000000000  0000000   
    # 000     000     000       000 0 000       000  
    # 000     000     00000000  000   000  0000000   

    addItem: (items, item) ->
        
        @addRectForItem item
        
        if items.length == 1
            @createRect()
            # @setBox item.rbox()
        # else
            # @setBox @rbox.merge item.rbox()
        @calcBox()
        
        if @selection.pos
            @drag.start @selection.pos
            
    delItem: (items, item) ->

        @delRectForItem item
        @calcBox()        
        # if @box
            # @setBox boxForItems items
    
    addRectForItem: (item) ->
        
        r = @svg.rect()
        r.addClass 'resizerItemRect'
        item.remember 'itemRect', r.id()
        @updateItem item

    delRectForItem: (item) ->
        
        if rectID = item.remember 'itemRect' 
            if rectID.startsWith 'SvgjsRect'
                log 'delRectForItem', rectID
            SVG.get(rectID)?.remove()
            item.forget 'itemRect'
        
    updateItems: ->
        # log "updateItems @box: #{@box.x} #{@box.y} #{@box.w} #{@box.h}"
        for item in @selection.items
            @updateItem item
        
    updateItem: (item) ->
        @setItemBox item, boxForItems [item], @viewPos()
        
    setItemBox: (item, box) ->
        
        r = SVG.get item.remember 'itemRect'
        r?.attr
            x:      box.x
            y:      box.y
            width:  box.w
            height: box.h

    itemBox: (item) -> boxForItems [item], @viewPos()
                        
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

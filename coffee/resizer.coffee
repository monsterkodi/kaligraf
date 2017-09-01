
# 00000000   00000000   0000000  000  0000000  00000000  00000000 
# 000   000  000       000       000     000   000       000   000
# 0000000    0000000   0000000   000    000    0000000   0000000  
# 000   000  000            000  000   000     000       000   000
# 000   000  00000000  0000000   000  0000000  00000000  000   000

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{ boxForItems, posForRect, moveBox, zoomBox } = require './utils'

class Resizer

    constructor: (@kali) ->

        @selection = @kali.stage.selection
        @element = elem 'div', id: 'resizer'
        @kali.element.appendChild @element
        
        @svg = SVG(@element).size '100%', '100%' 
        @svg.addClass 'resizerSVG'
        @svg.clear()
        
        @svg.node.addEventListener 'wheel', (event) => @kali.stage.onWheel event
        
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

    #  0000000    0000000  000000000  000  000   000   0000000   000000000  00000000  
    # 000   000  000          000     000  000   000  000   000     000     000       
    # 000000000  000          000     000   000 000   000000000     000     0000000   
    # 000   000  000          000     000     000     000   000     000     000       
    # 000   000   0000000     000     000      0      000   000     000     00000000  
    
    deactivate: -> @activate false
    
    activate: (active=true) ->
        if active
            @drag?.activate()
            @g?.removeClass 'resizerInactive'
            @svg?.removeClass 'resizerInactive'
        else
            @drag?.deactivate()
            @g?.addClass 'resizerInactive'
            @svg?.addClass 'resizerInactive'
            
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
        if left  then dx = -drag.delta.x
        if right then dx =  drag.delta.x
        if top   then dy = -drag.delta.y
        if bot   then dy =  drag.delta.y

        return if dx == 0 and dy == 0
        
        dx /= @kali.stage.zoom
        dy /= @kali.stage.zoom
        
        fx = (@sbox.w + dx)/@sbox.w
        fy = (@sbox.h + dy)/@sbox.h
        
        # log "fx #{fx} fy #{fy} sbox #{@sbox.w} #{@sbox.h}"
        
        if @sbox.w <= 10 and fx < 1 then fx = 1
        if @sbox.h <= 10 and fy < 1 then fy = 1
        
        for item in @selection.items
            
            if item.type == 'text'
                iw = item.rbox().width
                ih = item.rbox().height
            else
                iw = item.width()
                ih = item.height()
                
            # log "iw #{iw} ih #{ih}"

            if item.type in ['circle', 'text']
                
                if Math.abs(dx) > Math.abs(dy)
                    fy = fx
                else if Math.abs(dy) > Math.abs(dx)
                    fx = fy
                else
                    fx = fy = 1
                
            if item.type == 'circle'
                
                item.radius (iw * fx)/2.0
                
            else if item.type == 'text'

                item.font 'size', fx * item.font 'size'
                
            else
                item.size Math.max(iw * fx, 1), Math.max(ih * fy, 1)
                item.size iw * fx, ih * fy
            
            switch item.type
                    
                when 'circle', 'ellipse'
                    
                    cx = item.cx(); cy = item.cy(); nw = item.width(); nh = item.height()
                    
                    if right then item.cx nw/2 + @sbox.x  + fx * ((cx - iw/2) - @sbox.x)
                    if bot   then item.cy nh/2 + @sbox.y  + fy * ((cy - ih/2) - @sbox.y) 
                    if left  then item.cx nw/2 + @sbox.x2 - fx * (@sbox.x2 - (cx - iw/2))
                    if top   then item.cy nh/2 + @sbox.y2 - fy * (@sbox.y2 - (cy - ih/2))
                    
                when 'text'
                    
                    if right then item.x @sbox.x  + fx * (item.x() - @sbox.x) 
                    if bot   then item.y @sbox.y  + fy * (item.y() - @sbox.y)
                    if left  then item.x @sbox.x2 - fx * (@sbox.x2 - item.x())
                    if top   then item.y @sbox.y2 - fy * (@sbox.y2 - item.y())
                    
                else
                    z  = @kali.stage.zoom
                    x  = @sbox.x 
                    y  = @sbox.y 
                    x2 = @sbox.x2
                    y2 = @sbox.y2
                    
                    # log x, item.x(), z
                    
                    if right then item.x x  + fx * (item.x() - x) 
                    if bot   then item.y y  + fy * (item.y() - y)
                    if left  then item.x x2 - fx * (x2 - item.x())
                    if top   then item.y y2 - fy * (y2 - item.y())
                                                        
        @calcBox()         
                        
    # 0000000     0000000   000   000  
    # 000   000  000   000   000 000   
    # 0000000    000   000    00000    
    # 000   000  000   000   000 000   
    # 0000000     0000000   000   000  
    
    setBox: (@rbox) ->
        
        @box = new SVG.RBox @rbox
        
        moveBox @box, @viewPos().scale -1
        
        @g.attr 
            x:      @box.x
            y:      @box.y
            width:  @box.w
            height: @box.h
            
        @sbox = new SVG.RBox @box
        
        dx = @kali.stage.svg.viewbox().x
        dy = @kali.stage.svg.viewbox().y
        
        zoomBox @sbox, @kali.stage.zoom
        moveBox @sbox, pos dx, dy

    calcBox: ->
        
        if @selection.empty()
            @clear()
        else
            @setBox boxForItems @selection.items
            @updateItems()

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (drag, event) => 
        
        if event?.shiftKey
            @kali.stage.shapes.handleMouseDown event
            return 'skip'
    
    onDragStop: => 
    
    onDragMove: (drag) => @moveBy drag.delta
            
    moveBy: (delta) ->
        
        if not @selection.rect?
            @selection.moveBy delta
            @calcBox()
            
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
            
        @calcBox()
        
        if @selection.pos
            @drag.start @selection.pos
            
    delItem: (items, item) ->

        @delRectForItem item
        @calcBox()        
    
    addRectForItem: (item) ->
        
        r = @svg.rect()
        r.addClass 'resizerItemRect'
        item.remember 'itemRect', r.id()
        @updateItem item

    delRectForItem: (item) ->
        
        if rectID = item.remember 'itemRect' 
            # if rectID.startsWith 'SvgjsRect'
                # log '--', rectID, SVG.get(rectID)?
            SVG.get(rectID)?.remove()
            item.forget 'itemRect'
        # else
            # log '??', item.id()
        
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
    
    viewPos:  -> r = @element.getBoundingClientRect(); pos r.left, r.top
    viewSize: -> r = @element.getBoundingClientRect(); width:r.width, height:r.height
    
    onStage: (action, box) =>
        
        switch action
            when 'viewbox' then @calcBox()

    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event, down) ->
        
        if not @empty() and down
            switch combo
                when 'left', 'right', 'up', 'down'
                    p = pos 0, 0
                    switch key
                        when 'left'  then p.x = -1
                        when 'right' then p.x =  1
                        when 'up'    then p.y = -1
                        when 'down'  then p.y =  1
                    return @moveBy p
                    
        'unhandled'
            
module.exports = Resizer

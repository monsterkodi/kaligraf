
# 00000000   00000000   0000000  000  0000000  00000000  00000000
# 000   000  000       000       000     000   000       000   000
# 0000000    0000000   0000000   000    000    0000000   0000000
# 000   000  000            000  000   000     000       000   000
# 000   000  00000000  0000000   000  0000000  00000000  000   000

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{ boxForItems, posForRect, moveBox, zoomBox, scaleBox, boxOffset, boxSize } = require './utils'

class Resizer

    constructor: (@kali) ->

        @trans = @kali.trans
        
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

        post.on 'stage',     @onStage
        post.on 'selection', @onSelection

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    onResizeMove:  (drag, event) =>

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

        fx = (@sbox.w + dx)/@sbox.w
        fy = (@sbox.h + dy)/@sbox.h

        if @sbox.w <= 10 and fx < 1 then fx = 1
        if @sbox.h <= 10 and fy < 1 then fy = 1

        z = @kali.stage.zoom
        vo = boxOffset @kali.stage.svg.viewbox()
        tl = boxOffset(@sbox)                     .minus(vo).scale(1.0/z).plus(vo) 
        br = boxOffset(@sbox).plus(boxSize(@sbox)).minus(vo).scale(1.0/z).plus(vo)
        
        for item in @selection.items

            iw = @trans.width  item
            ih = @trans.height item

            if item.type in ['circle', 'text']

                if Math.abs(dx) > Math.abs(dy)
                    fr = fx
                else if Math.abs(dy) > Math.abs(dx)
                    fr = fy
                else
                    fr = 1

            if item.type == 'circle'

                item.radius (iw * fr)/2.0

            else if item.type == 'text'

                c = @trans.center item
                item.font 'size', fr * item.font 'size'
                @trans.center item, c
                
            else if item.type in ['polygon', 'polyline', 'line']
                
                c = @trans.center item
                item.size iw * fx, ih * fy
                item.center 0,0
                @trans.center item, c
                
            else
                item.size iw * fx, ih * fy

            if item.type in ['circle', 'text'] 
                ax = ay = fr
            else
                ax = fx
                ay = fy
                            
            if left  then @trans.center item, pos                        @trans.width(item)  / 2 + br.x - ax * (br.x - (@trans.center(item).x - iw/2)), @trans.center(item).y
            if top   then @trans.center item, pos @trans.center(item).x, @trans.height(item) / 2 + br.y - ay * (br.y - (@trans.center(item).y - ih/2))
            if right then @trans.center item, pos                        @trans.width(item)  / 2 + tl.x + fx * ((@trans.center(item).x - iw/2) - tl.x), @trans.center(item).y
            if bot   then @trans.center item, pos @trans.center(item).x, @trans.height(item) / 2 + tl.y + fy * ((@trans.center(item).y - ih/2) - tl.y)
                    
        @calcBox()
        @selection.updateItems()

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

        @sbox = new SVG.RBox @box # in view coordinates

        dx = @kali.stage.svg.viewbox().x
        dy = @kali.stage.svg.viewbox().y

        zoomBox @sbox, @kali.stage.zoom
        moveBox @sbox, pos dx, dy

    calcBox: ->

        if @selection.empty()
            @clear()
        else
            @setBox boxForItems @selection.items

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
            when 'set'   then @setItems items
            when 'add'   then @addItem  items, item
            when 'del'   then @delItem  items, item
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

    setItems: (items) ->

        if items.length
            @createRect()
            @updateBox()
        else
            @clear()

    addItem: (items, item) ->

        if items.length == 1
            @createRect()
            @rbox = item.rbox()

        @updateBox()

        if @selection.pos
            @drag.start @selection.pos

    delItem: (items, item) -> @updateBox()

    updateBox: ->
        
        box = @selection.svg.bbox()
        moveBox  box, boxOffset(@kali.stage.svg.viewbox()).scale -1
        scaleBox box, @kali.stage.zoom
        moveBox  box, boxOffset @viewPos()
        @setBox  box

    # 000   000  000  00000000  000   000
    # 000   000  000  000       000 0 000
    #  000 000   000  0000000   000000000
    #    000     000  000       000   000
    #     0      000  00000000  00     00

    viewPos:  -> r = @element.getBoundingClientRect(); pos r.left, r.top
    viewSize: -> r = @element.getBoundingClientRect(); pos r.width, r.height

    onStage: (action, box) =>

        if action == 'viewbox' then @calcBox()

    # 000   000  00000000  000   000
    # 000  000   000        000 000
    # 0000000    0000000     00000
    # 000  000   000          000
    # 000   000  00000000     000

    handleKey: (mod, key, combo, char, event, down) ->

        if not @empty() and down
            switch combo
                when 'left', 'right', 'up', 'down'
                    p = pos 0,0
                    switch key
                        when 'left'  then p.x = -1
                        when 'right' then p.x =  1
                        when 'up'    then p.y = -1
                        when 'down'  then p.y =  1
                    return @moveBy p

        'unhandled'

module.exports = Resizer

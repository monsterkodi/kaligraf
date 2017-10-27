
# 00000000   00000000   0000000  000  0000000  00000000  00000000
# 000   000  000       000       000     000   000       000   000
# 0000000    0000000   0000000   000    000    0000000   0000000
# 000   000  000            000  000   000     000       000   000
# 000   000  00000000  0000000   000  0000000  00000000  000   000

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{   opposide,  rectSize, rectOffset, itemIDs
    moveBox,   zoomBox,  scaleBox
    boxOffset, boxPos,   boxSize } = require './utils'

Cursor = require './cursor'
    
class Resizer

    constructor: (@kali) ->

        @name  = 'Resizer'
        @trans = @kali.trans
        @stage = @kali.stage
        
        @selection = @stage.selection
        @element = elem 'div', id: 'resizer'
        @kali.insertBelowTools @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.id 'Resizer'
        @svg.addClass 'resizerSVG'
        @svg.clear()

        @svg.node.addEventListener 'wheel', (event) => @stage.onWheel event

        @box  = null
        @rect = null

        @borderDrag = {}
        @cornerDrag = {}
        @rotDrag    = {}

        post.on 'stage',     @onStage
        post.on 'selection', @onSelection

    do: (action) -> @stage.undo.do @, action
    done:        -> @stage.undo.done   @
        
    # 00000000    0000000   000000000   0000000   000000000  000   0000000   000   000  
    # 000   000  000   000     000     000   000     000     000  000   000  0000  000  
    # 0000000    000   000     000     000000000     000     000  000   000  000 0 000  
    # 000   000  000   000     000     000   000     000     000  000   000  000  0000  
    # 000   000   0000000      000     000   000     000     000   0000000   000   000  
    
    onRotation: (drag, event) =>
                
        if Math.abs(drag.delta.x) > Math.abs(drag.delta.y)
            d = drag.delta.x
        else
            d = drag.delta.y

        sp = @stage.stageForEvent drag.startPos
        ep = @stage.stageForEvent drag.pos
        v1 = sp.minus @rotationCenter 
        v2 = ep.minus @rotationCenter
        angle = v2.rotation v1
        
        if event.shiftKey
            angle = Math.round(angle/15) * 15
            
        @doRotate angle, round:event.shiftKey
        
    doRotate: (angle, opt) ->
           
        return if angle == 0
        
        @do 'rotate'+itemIDs @selection.items
        
        transmat = new SVG.Matrix().around @rotationCenter.x, @rotationCenter.y, new SVG.Matrix().rotate angle

        for {item, rotation, center} in @itemRotation
            newAngle = angle+rotation
            newAngle = Math.round newAngle if opt?.round
            @trans.rotation item, newAngle
            newCenter = pos new SVG.Point(center).transform transmat
            @trans.center item, newCenter
            
        @selection.update()
        
        p = boxPos @rect.bbox(), opposide @rotationCorner
        @gg.transform rotation:angle, cx:p.x, cy:p.y
        
        @done()
        
        post.emit 'resizer', 'rotation'
    
    #  0000000   000   000   0000000   000      00000000  
    # 000   000  0000  000  000        000      000       
    # 000000000  000 0 000  000  0000  000      0000000   
    # 000   000  000  0000  000   000  000      000       
    # 000   000  000   000   0000000   0000000  00000000  
    
    setAngle: (angle) ->
        
        @itemRotation = @getItemRotation()
        @rotationCenter = boxPos @selection.bbox(), opposide 'center'
        @doRotate angle - @angle()
        delete @itemRotation
        delete @rotationCenter
        @update()
       
    addAngle: (angle) -> @setAngle @angle() + angle
        
    angle: ->

        angles = @selection.items.map (item) -> item.transform().rotation
        _.sum(angles) / angles.length
        
    # 00000000   00000000   0000000  000  0000000  00000000  
    # 000   000  000       000       000     000   000       
    # 0000000    0000000   0000000   000    000    0000000   
    # 000   000  000            000  000   000     000       
    # 000   000  00000000  0000000   000  0000000  00000000  

    onResize: (drag, event) =>
        
        return if drag.delta.x == 0 and drag.delta.dy == 0
        
        center = drag.id
        items = @selection.items
        
        delta = pos drag.delta
                
        left  = center.includes 'left'
        right = center.includes 'right'
        top   = center.includes 'top'
        bot   = center.includes 'bot'

        if not left and not right then delta.x = 0
        if not top  and not bot   then delta.y = 0

        if not event.metaKey
            box    = @selection.bbox()
            sdelta = delta.times 1/@stage.zoom
            sdelta = @kali.tool('snap').delta sdelta, box:box, side:center, items:items
            delta  = sdelta.times @stage.zoom 
        else
            @kali.tool('snap').clear()
        
        if left then delta.x = -delta.x
        if top  then delta.y = -delta.y

        aspect = @sbox.w / @sbox.h
        
        if not event.shiftKey
            if Math.abs(delta.x) > Math.abs(delta.y)
                delta.y = delta.x / aspect
            else
                delta.x = delta.y * aspect

        if event.ctrlKey
            delta.x *= 2
            delta.y *= 2
            center = 'center'
            
        sx = (@sbox.w + delta.x)/@sbox.w
        sy = (@sbox.h + delta.y)/@sbox.h
                
        resizeCenter = boxPos @selection.bbox(), opposide center
        transmat = new SVG.Matrix().around resizeCenter.x, resizeCenter.y, new SVG.Matrix().scale sx, sy

        @do 'resize'
                
        for item in items
            
            @trans.resize item, transmat, pos sx, sy
            
        @selection.update()
        @update()
        
        @done()
        
        post.emit 'resizer', 'resize'
        
    # 00000000   00000000   0000000  000000000
    # 000   000  000       000          000
    # 0000000    0000000   000          000
    # 000   000  000       000          000
    # 000   000  00000000   0000000     000

    createRect: ->

        @g = @svg.nested()
        @g.addClass 'resizerGroup'
        @gg = @g.group()

        @rect = @gg.rect().addClass 'resizerRect'
        @rect.attr width: '100%', height: '100%'
        
        
        addBorder = (x, y, w, h, cursor, id) =>
            group  = @gg.nested() 
            group.attr   x:x, y:y
            border = group.rect()
            border.addClass 'resizerBorder'
            border.attr  x:-3, y:-3
            border.attr  width:w, height:h
            border.style cursor: cursor
            @borderDrag[id] = new drag
                target:  border.node
                onStart: @onBorderStart
                onMove:  @onBorderMove
                onStop:  @onBorderStop
            @borderDrag[id].id = id

        addBorder 0,      0, 6, '100%', 'ew-resize', 'left'
        addBorder '100%', 0, 6, '100%', 'ew-resize', 'right'
        addBorder 0,      0, '100%', 6, 'ns-resize', 'top'
        addBorder 0, '100%', '100%', 6, 'ns-resize', 'bot'

        
        addCorner = (x, y, cursor, id, path) =>
            group  = @gg.nested() 
            group.attr x:x, y:y
            corner = group.path(path).addClass 'resizerCorner'
            corner.attr x:-10, y:-10
            corner.style cursor:cursor
            @cornerDrag[id] = new drag
                target:  corner.node
                onStart: @onCornerStart
                onMove:  @onCornerMove
                onStop:  @onCornerStop
            @cornerDrag[id].id = id
            
        addCorner '100%',      0, 'ne-resize', 'top right', 'M10,-10L10,10L0,10L0,0L-10,0L-10,-10Z'
        addCorner 0,      '100%', 'sw-resize', 'bot left',  'M-10,10L-10,-10L0,-10L0,0L10,0L10,10Z'
        addCorner 0,           0, 'nw-resize', 'top left',  'M-10,-10L-10,10L0,10L0,0L10,0L10,-10Z'
        addCorner '100%', '100%', 'se-resize', 'bot right', 'M10,10L10,-10L0,-10L0,0L-10,0L-10,10Z'

        addRot = (x, y, r, id) =>
            rot = @gg.circle(r).addClass 'resizerRot'
            rot.attr cx:x, cy:y
            rot.style cursor: Cursor.forTool 'rot ' + id
            @rotDrag[id] = new drag
                    target:  rot.node
                    onStart: @onRotStart
                    onMove:  @onRotMove
                    onStop:  @onRotStop
            @rotDrag[id].id = id
                   
        addRot      0,      0, 10, 'top left'
        addRot '100%',      0, 10, 'top right'
        addRot      0, '100%', 10, 'bot left'
        addRot '100%', '100%', 10, 'bot right'

        addRot      0,  '50%', 10, 'left'
        addRot '100%',  '50%', 10, 'right'
        addRot  '50%',      0, 10, 'top'
        addRot  '50%', '100%', 10, 'bot'        
        
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
            @svg?.removeClass 'resizerInactive'
        else
            @drag?.deactivate()
            @svg?.addClass 'resizerInactive'

    # 00000000   00000000   0000000  000  0000000  00000000
    # 000   000  000       000       000     000   000
    # 0000000    0000000   0000000   000    000    0000000
    # 000   000  000            000  000   000     000
    # 000   000  00000000  0000000   000  0000000  00000000

    onCornerStart: (drag, event) => @onStart()
    onCornerMove:  (drag, event) => @onResize   drag, event
    onCornerStop:  (drag, event) => @kali.tool('snap').clear()
    onBorderStart: (drag, event) => @onStart()
    onBorderMove:  (drag, event) => @onResize   drag, event
    onBorderStop:  (drag, event) => @kali.tool('snap').clear()
    onRotMove:     (drag, event) => @onRotation drag, event
    
    onRotStart: (drag, event) =>
        
        @onStart()
        @rotationCorner = drag.id
        if event.ctrlKey
            @rotationCorner = 'center'
        @rotationCenter = boxPos @selection.bbox(), opposide @rotationCorner
        
    onRotStop: (drag, event) => 
        
        @updateBox()
        
        delete @itemRotation

    onStart: =>
        
        if @kali.shapeTool() != 'pick'
            @kali.tools.activateTool 'pick'
        
        @itemRotation = @getItemRotation()
        
    getItemRotation: ->
        
        @selection.items.map (item) => 
            item:       item
            rotation:   @trans.rotation item 
            center:     @trans.center item 
        
    # 0000000    00000000    0000000    0000000
    # 000   000  000   000  000   000  000
    # 000   000  0000000    000000000  000  0000
    # 000   000  000   000  000   000  000   000
    # 0000000    000   000  000   000   0000000

    onDragStart: (drag, event) =>

        log 'Resizer.onDragStart'
        @onStart()
            
        if event?.shiftKey
            @stage.shapes.handleMouseDown event
            return 'skip'

    onDragMove: (drag, event) => 

        @moveBy drag.delta, event

    onDragStop: (drag) => 
        
        @delete @drag.shift
    
    moveBy: (delta, event) ->

        if not @selection.rect?
            @selection.moveBy delta, event
            @update()

    #  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
    # 000       000       000      000       000          000     000  000   000  0000  000
    # 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
    #      000  000       000      000       000          000     000  000   000  000  0000
    # 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

    onSelection: (action, items, item) =>

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

        for k,d of @rotDrag
            d.deactivate()
        @rotDrag = {}

    # 000  000000000  00000000  00     00   0000000
    # 000     000     000       000   000  000
    # 000     000     0000000   000000000  0000000
    # 000     000     000       000 0 000       000
    # 000     000     00000000  000   000  0000000

    setItems: (items) ->

        if items.length
            @createRect()
        @update()

    addItem: (items, item) ->

        if items.length == 1
            @createRect()

        @updateBox()

    delItem: (items, item) -> @update()

    # 0000000     0000000   000   000
    # 000   000  000   000   000 000
    # 0000000    000   000    00000
    # 000   000  000   000   000 000
    # 0000000     0000000   000   000

    update: -> 

        if @selection.empty()
            @clear()
        else
            @updateBox()
    
    updateBox: ->
        
        @gg.transform rotation:0
        @gg.transform x:0, y:0
        
        box = @selection.bbox()
        moveBox  box, boxOffset(@stage.svg.viewbox()).scale -1
        scaleBox box, @stage.zoom
        moveBox  box, boxOffset @viewPos()
        @setBox  box

    setBox: (box) ->

        @box = new SVG.RBox box

        moveBox @box, @viewPos().scale -1

        @g.attr
            x:      @box.x
            y:      @box.y
            width:  @box.w
            height: @box.h
            
        @sbox = new SVG.RBox @box # in view coordinates

        zoomBox @sbox, @stage.zoom
        moveBox @sbox, boxOffset @stage.svg.viewbox()
        
    # 000   000  000  00000000  000   000
    # 000   000  000  000       000 0 000
    #  000 000   000  0000000   000000000
    #    000     000  000       000   000
    #     0      000  00000000  00     00

    viewPos:  -> r = @element.getBoundingClientRect(); pos r.left, r.top
    viewSize: -> r = @element.getBoundingClientRect(); pos r.width, r.height

    onStage: (action, box) =>

        if action == 'viewbox' then @update()

    # 000   000  00000000  000   000
    # 000  000   000        000 000
    # 0000000    0000000     00000
    # 000  000   000          000
    # 000   000  00000000     000

    handleKey: (mod, key, combo, char, event, down) ->

        'unhandled'

module.exports = Resizer

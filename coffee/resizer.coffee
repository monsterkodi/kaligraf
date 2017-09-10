
# 00000000   00000000   0000000  000  0000000  00000000  00000000
# 000   000  000       000       000     000   000       000   000
# 0000000    0000000   0000000   000    000    0000000   0000000
# 000   000  000            000  000   000     000       000   000
# 000   000  00000000  0000000   000  0000000  00000000  000   000

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{   opposide,  rectSize, rectOffset, 
    moveBox,   zoomBox,  scaleBox,
    boxOffset, boxPos,   boxSize, boxForItems } = require './utils'

class Resizer

    constructor: (@kali) ->

        @trans = @kali.trans
        
        @selection = @kali.stage.selection
        @element = elem 'div', id: 'resizer'
        @kali.insertBelowTools @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'resizerSVG'
        @svg.clear()

        @svg.node.addEventListener 'wheel', (event) => @kali.stage.onWheel event

        @box  = null
        @rect = null

        @borderDrag = {}
        @cornerDrag = {}
        @rotDrag    = {}

        post.on 'stage',     @onStage
        post.on 'selection', @onSelection

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

        sp = @kali.stage.stageForEvent drag.lastPos
        ep = @kali.stage.stageForEvent drag.pos
        v1 = sp.minus @rotationCenter 
        v2 = ep.minus @rotationCenter
        angle = v1.rotation v2
        return if angle == 0
            
        transmat = new SVG.Matrix().around @rotationCenter.x, @rotationCenter.y, new SVG.Matrix().rotate angle

        for item in @selection.items
            oldCenter = @trans.center item
            @trans.rotation item, angle + @trans.rotation item
            newCenter = pos new SVG.Point(oldCenter).transform transmat
            @trans.center item, newCenter
            
        @selection.updateItems()
        
        p = boxPos @rect.bbox(), opposide @rotationCorner
        @gg.transform rotation:@gg.transform('rotation')+angle, cx:p.x, cy:p.y
    
    # 00000000   00000000   0000000  000  0000000  00000000  
    # 000   000  000       000       000     000   000       
    # 0000000    0000000   0000000   000    000    0000000   
    # 000   000  000            000  000   000     000       
    # 000   000  00000000  0000000   000  0000000  00000000  

    onResize: (drag, event) =>

        dx = drag.delta.x
        dy = drag.delta.y
        
        return if dx == 0 and dy == 0

        center = drag.id
        
        left  = center.includes 'left'
        right = center.includes 'right'
        top   = center.includes 'top'
        bot   = center.includes 'bot'

        if not left and not right then dx = 0
        if not top  and not bot   then dy = 0
                
        if left then dx = -dx
        if top  then dy = -dy

        aspect = @sbox.w / @sbox.h
        
        if not event.shiftKey
            if Math.abs(dx) > Math.abs(dy)
                dy = dx / aspect
            else
                dx = dy * aspect

        if event.ctrlKey
            dx *= 2
            dy *= 2
            center = 'center'
            
        sx = (@sbox.w + dx)/@sbox.w
        sy = (@sbox.h + dy)/@sbox.h
                
        resizeCenter = boxPos @selection.svg.bbox(), opposide center
        transmat = new SVG.Matrix().around resizeCenter.x, resizeCenter.y, new SVG.Matrix().scale sx, sy

        for item in @selection.items
            
            @trans.resize item, transmat, pos sx, sy
            
        @selection.updateItems()
        @calcBox()
        
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
            @borderDrag[id].id = id

        addBorder 0,      0, 6, '100%', 'ew-resize', 'left'
        addBorder '100%', 0, 6, '100%', 'ew-resize', 'right'
        addBorder 0,      0, '100%', 6, 'ns-resize', 'top'
        addBorder 0, '100%', '100%', 6, 'ns-resize', 'bot'

        
        addCorner = (x, y, cursor, id, path) =>
            group  = @gg.nested() 
            group.attr x:x, y:y
            # corner = group.rect(20,20).addClass 'resizerCorner'
            corner = group.path(path).addClass 'resizerCorner'
            corner.attr x:-10, y:-10
            corner.style cursor:cursor
            @cornerDrag[id] = new drag
                target:  corner.node
                onStart: @onCornerStart
                onMove:  @onCornerMove
            @cornerDrag[id].id = id
            
        addCorner '100%',      0, 'ne-resize', 'top right', 'M10,-10L10,10L0,10L0,0L-10,0L-10,-10Z'
        addCorner 0,      '100%', 'sw-resize', 'bot left',  'M-10,10L-10,-10L0,-10L0,0L10,0L10,10Z'
        addCorner 0,           0, 'nw-resize', 'top left',  'M-10,-10L-10,10L0,10L0,0L10,0L10,-10Z'
        addCorner '100%', '100%', 'se-resize', 'bot right', 'M10,10L10,-10L0,-10L0,0L-10,0L-10,10Z'

        
        addRot = (x, y, r, id) =>
            rot = @gg.circle(r).addClass 'resizerRot'
            rot.attr cx:x, cy:y
            cursor = "file://#{__dirname}/../svg/rot.svg"
            rot.style cursor: "url(#{cursor}) 18 12, auto"
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
    onBorderStart: (drag, event) => @onStart()
    onBorderMove:  (drag, event) => @onResize   drag, event
    onRotMove:     (drag, event) => @onRotation drag, event
    
    onRotStart: (drag, event) =>
        
        @onStart()
        @rotationCorner = drag.id
        if event.ctrlKey
            @rotationCorner = 'center'
        @rotationCenter = boxPos @selection.svg.bbox(), opposide @rotationCorner
        
    onRotStop: (drag, event) => 
        
        @gg.transform rotation:0
        @gg.transform x:0, y:0
        @updateBox()

    onStart: =>
        
        if @kali.shapeTool() != 'pick'
            @kali.tools.activateTool 'pick'
        
    # 0000000    00000000    0000000    0000000
    # 000   000  000   000  000   000  000
    # 000   000  0000000    000000000  000  0000
    # 000   000  000   000  000   000  000   000
    # 0000000    000   000  000   000   0000000

    onDragStart: (drag, event) =>

        @onStart()
            
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
        @calcBox()

    addItem: (items, item) ->

        if items.length == 1
            @createRect()

        @updateBox()

        if @selection.pos
            @drag.start @selection.pos

    delItem: (items, item) -> @calcBox()

    # 0000000     0000000   000   000
    # 000   000  000   000   000 000
    # 0000000    000   000    00000
    # 000   000  000   000   000 000
    # 0000000     0000000   000   000

    calcBox: -> 

        if @selection.empty()
            @clear()
        else
            @updateBox()
    
    updateBox: ->
        
        box = @selection.svg.bbox()
        moveBox  box, boxOffset(@kali.stage.svg.viewbox()).scale -1
        scaleBox box, @kali.stage.zoom
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

        zoomBox @sbox, @kali.stage.zoom
        moveBox @sbox, boxOffset @kali.stage.svg.viewbox()
        
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

        # if not @empty() and down
            # switch combo
                # when 'left', 'right', 'up', 'down'
                    # p = pos 0,0
                    # switch key
                        # when 'left'  then p.x = -1
                        # when 'right' then p.x =  1
                        # when 'up'    then p.y = -1
                        # when 'down'  then p.y =  1
                    # return @moveBy p

        'unhandled'

module.exports = Resizer


# 00000000   00000000   0000000  000  0000000  00000000  00000000
# 000   000  000       000       000     000   000       000   000
# 0000000    0000000   0000000   000    000    0000000   0000000
# 000   000  000            000  000   000     000       000   000
# 000   000  00000000  0000000   000  0000000  00000000  000   000

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{ opposide, moveBox, zoomBox, scaleBox, boxCenter, boxOffset, boxPos, boxRelPos } = require '../utils'

Cursor = require '../cursor'
    
class Resizer

    constructor: (@kali) ->

        @trans = @kali.trans
        @stage = @kali.stage
        @selection = @stage.selection
        
        @element = elem 'div', id:@name
        if @name == 'ItemRes'
            @kali.insertBelowTools @element
        else
            @kali.insertAboveStage @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.id @name+'SVG'
        @svg.addClass 'resizerSVG'
        @svg.clear()

        @svg.node.addEventListener 'wheel', (event) => @stage.onWheel event

        @box  = null
        @rect = null

        @borderDrag = {}
        @cornerDrag = {}
        @rotDrag    = {}

        post.on 'stage', @onStage

    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    del: ->
        
        @svg.clear()
        @svg.remove()
        @element.remove()
        post.removeListener 'stage',  @onStage

    do: (action) -> @stage.undo.do   @, action
    done:        -> @stage.undo.done @
        
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
        
        
        @rotKnob = @gg.circle(10,10)
        @rotKnob.addClass 'resizerCenter'
        @setRotationCorner 'center'

        @rotDrag['center'] = new drag
            target:  @rotKnob.node
            onMove:  @onRotKnobMove
            onStop:  @onRotKnobStop
        
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

        addCorner = (x, y, cx, cy, cursor, id) =>
            group = @gg.nested() 
            group.attr x:x, y:y
            corner = group.rect(20,20).addClass 'resizerCorner'
            corner.cx cx
            corner.cy cy
            corner.style cursor:cursor
            @cornerDrag[id] = new drag
                target:  corner.node
                onStart: @onCornerStart
                onMove:  @onCornerMove
                onStop:  @onCornerStop
            @cornerDrag[id].id = id
            
        addCorner 0,           0, -10, -10, 'nw-resize', 'top left'  
        addCorner '100%',      0,  10, -10, 'ne-resize', 'top right' 
        addCorner '100%', '100%',  10,  10, 'se-resize', 'bot right' 
        addCorner 0,      '100%', -10,  10, 'sw-resize', 'bot left'  

        addCorner 0,      '50%', -10,   0, 'ew-resize', 'left' 
        addCorner '100%', '50%',  10,   0, 'ew-resize', 'right'
        addCorner '50%',      0,   0, -10, 'ns-resize', 'top'  
        addCorner '50%', '100%',   0,  10, 'ns-resize', 'bot'  
        
        addRot = (x, y, r, cx, cy, id) =>
            group = @gg.nested() 
            group.attr x:x, y:y
            rot = group.circle(r).addClass 'resizerRot'
            rot.attr cx:cx, cy:cy
            rot.style cursor: Cursor.forTool 'rot ' + id
            @rotDrag[id] = new drag
                    target:  rot.node
                    onStart: @onRotStart
                    onMove:  @onRotMove
                    onStop:  @onRotStop
            @rotDrag[id].id = id
                   
        addRot      0,      0, 14, -7, -7, 'top left'
        addRot '100%',      0, 14,  7, -7, 'top right'
        addRot      0, '100%', 14, -7,  7, 'bot left'
        addRot '100%', '100%', 14,  7,  7, 'bot right'

        addRot      0,  '50%', 14, -7,  0, 'left'
        addRot '100%',  '50%', 14,  7,  0, 'right'
        addRot  '50%',      0, 14,  0, -7, 'top'
        addRot  '50%', '100%', 14,  0,  7, 'bot'        
        
        @drag = new drag
            target:  @rect.node
            onMove:  @onDragMove
            onStop:  @onDragStop
            
        # log 'createRect', @name, @svg.id(), @svg.children().length, @svg.bbox()

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

    # 00000000    0000000   000000000      000   0000000  000  0000000  00000000
    # 000   000  000   000     000        000   000       000     000   000
    # 0000000    000   000     000       000    0000000   000    000    0000000
    # 000   000  000   000     000      000          000  000   000     000
    # 000   000   0000000      000     000      0000000   000  0000000  00000000

    onCornerStart: (drag, event) => @onStart()
    onCornerMove:  (drag, event) => @onResize   drag, event
    onCornerStop:  (drag, event) => @kali.tool('snap').clear()
    onBorderStart: (drag, event) => @onStart()
    onBorderMove:  (drag, event) => @onResize   drag, event
    onBorderStop:  (drag, event) => @kali.tool('snap').clear()
    onRotMove:     (drag, event) => @onRotation drag, event
    
    onRotStart: (drag, event) =>
        
        @onStart()
        if event.ctrlKey
            @setRotationCorner 'center'
        else
            @setRotationCorner drag.id

    onRotStop: (drag, event) => 
        
        @updateBox()
        @setRotationCorner 'center'
        
    onStart: =>
            
    setRotationCorner: (@rotationCorner) ->
            
        if @rotationCorner == 'center'
            
            if @customCenter
                
                box = @bbox()
                bps = boxPos box
                x = bps.x + 0.01 * @customCenter.x * box.w
                y = bps.y + 0.01 * @customCenter.y * box.h
                center = pos x, y
                @setRotationCenter center, true
                
            else
                
                @setRotationCenter @calcCenter()
            
        else
            
            box = @bbox()
            center = boxPos box, opposide @rotationCorner
        
            @setRotationCenter center
        
    setRotationCenter: (@rotationCenter, custom) ->
        
        perc = @percCenter @rotationCenter
        
        if custom
            @customCenter = perc
        
        @rotKnob.attr 
            cx: "#{perc.x}%"
            cy: "#{perc.y}%"

    calcCenter: -> boxCenter @bbox()
            
    percCenter: (stagePos) ->
        
        box = @bbox()
        toRot = boxPos(box).to stagePos
        percx = 100 * toRot.x / box.w
        percy = 100 * toRot.y / box.h
        pos percx, percy
            
    onRotKnobMove: (drag, event) =>
            
        @setRotationCenter @stage.stageForEvent(pos event), true

    didRotate: (angle) ->
        
        if @customCenter
            p = boxRelPos @rect.bbox(), @customCenter.times 0.01
        else
            p = boxPos @rect.bbox(), opposide @rotationCorner
            
        @gg.transform rotation:angle, cx:p.x, cy:p.y
            
    onRotKnobStop: (drag, event) =>
        
        if drag.startPos == drag.lastPos
            delete @customCenter
            @setRotationCorner 'center'
                                    
    # 0000000    00000000    0000000    0000000
    # 000   000  000   000  000   000  000
    # 000   000  0000000    000000000  000  0000
    # 000   000  000   000  000   000  000   000
    # 0000000    000   000  000   000   0000000

    onDragMove: (drag, event) => 

        @moveBy drag.delta, event

    moveBy: (delta, event) ->
        
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

    # 0000000     0000000   000   000
    # 000   000  000   000   000 000
    # 0000000    000   000    00000
    # 000   000  000   000   000 000
    # 0000000     0000000   000   000

    update: -> 

        if @empty()
            @clear()
        else
            @updateBox()
    
    updateBox: ->

        return if not @gg?
        
        @gg.transform rotation:0
        @gg.transform x:0, y:0
        
        @setBox @bbox()
        
    setBox: (box) ->

        @box = new SVG.RBox box
        moveBox  @box, boxOffset(@stage.svg.viewbox()).scale -1
        scaleBox @box, @stage.zoom
        moveBox  @box, boxOffset @viewPos()

        @g.attr
            x:      @box.x
            y:      @box.y
            width:  @box.w
            height: @box.h
                    
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

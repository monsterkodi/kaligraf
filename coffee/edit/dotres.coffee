
# 0000000     0000000   000000000  00000000   00000000   0000000  000  0000000  00000000  00000000
# 000   000  000   000     000     000   000  000       000       000     000   000       000   000
# 000   000  000   000     000     0000000    0000000   0000000   000    000    0000000   0000000
# 000   000  000   000     000     000   000  000            000  000   000     000       000   000
# 0000000     0000000      000     000   000  00000000  0000000   000  0000000  00000000  000   000

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{   opposide,  rectSize, rectOffset, 
    moveBox,   zoomBox,  scaleBox,
    boxOffset, boxPos,   boxSize } = require '../utils'

Cursor = require '../cursor'
    
class DotResizer

    constructor: (@dotsel) ->

        @name  = 'DotRes' 
        @kali  = @dotsel.kali
        @trans = @kali.trans
        @stage = @kali.stage
        
        @element = elem 'div', id: 'dotres'
        @kali.insertAboveStage @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.id 'DotRes'
        @svg.addClass 'resizerSVG'
        @svg.clear()

        @svg.node.addEventListener 'wheel', (event) => @stage.onWheel event

        @box  = null
        @rect = null

        @borderDrag = {}
        @cornerDrag = {}
        @rotDrag    = {}

        post.on 'stage',  @onStage
        post.on 'dotsel', @onDotSel

    del: ->
        @svg.clear()
        @svg.remove()
        @element.remove()
        post.removeListener 'stage',  @onStage
        post.removeListener 'dotsel', @onDotSel
        
    do: (action) -> @stage.undo.do @, action
    done:        -> @stage.undo.done @
        
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
        angle = v1.rotation v2
        
        if event.shiftKey
            angle = Math.round(angle/15) * 15
            
        @doRotate angle, round:event.shiftKey
        
    doRotate: (angle, opt) ->
           
        return if angle == 0
        
        angle = Math.round angle if opt?.round
        
        doKey = 'rotate'+(@dotInfo.map (info) -> " #{info.dot.ctrl.index()}-#{info.dot.dot}").join ''

        @do doKey
        
        transmat = new SVG.Matrix().around @rotationCenter.x, @rotationCenter.y, new SVG.Matrix().rotate angle

        for {dot, center} in @dotInfo
            newCenter = pos new SVG.Point(center).transform transmat
            dot.cx newCenter.x
            dot.cy newCenter.y
            
        @dotsel.update()
        
        p = boxPos @rect.bbox(), opposide @rotationCorner
        @gg.transform rotation:angle, cx:p.x, cy:p.y
        
        @done()
        
        post.emit 'dotres', 'rotation'
    
    #  0000000   000   000   0000000   000      00000000  
    # 000   000  0000  000  000        000      000       
    # 000000000  000 0 000  000  0000  000      0000000   
    # 000   000  000  0000  000   000  000      000       
    # 000   000  000   000   0000000   0000000  00000000  
    
    setAngle: (angle) ->
        
        @dotInfo = @getDotInfo
        @rotationCenter = boxPos @dotsel.bbox(), opposide 'center'
        @doRotate angle - @angle()
        delete @rotationCenter
        delete @dotInfo
        @update()
        
    angle: -> @rect.transform().rotation
               
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
                
        resizeCenter = boxPos @dotsel.bbox(), opposide center
        transmat = new SVG.Matrix().around resizeCenter.x, resizeCenter.y, new SVG.Matrix().scale sx, sy

        @do 'resize'
                
        for dot in @dotsel.dots
            
            oldCenter = @trans.getCenter dot
            newCenter = new SVG.Point oldCenter
            newCenter = newCenter.transform transmat
    
            dot.cx newCenter.x
            dot.cy newCenter.y
            
        @dotsel.update()
        @update()
        
        @done()
        
        # post.emit 'dotres', 'resize'
        
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
            constrainKey: 'shiftKey'

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
        @rotationCenter = boxPos @dotsel.bbox(), opposide @rotationCorner
        
    onRotStop: (drag, event) => 
        
        @updateBox()
        
        delete @dotInfo

    onStart: =>
        
        if @kali.shapeTool() != 'edit'
            @kali.tools.activateTool 'edit'
        
        @dotInfo = @getDotInfo()
        
    getDotInfo: ->
        
        @dotsel.dots.map (dot) => 
            dot:        dot
            center:     @trans.center dot
        
    # 0000000    00000000    0000000    0000000
    # 000   000  000   000  000   000  000
    # 000   000  0000000    000000000  000  0000
    # 000   000  000   000  000   000  000   000
    # 0000000    000   000  000   000   0000000

    onDragStart: (drag, event) =>

        @onStart()
            
        if event?.shiftKey
            @stage.shapes.handleMouseDown event
            return 'skip'

    onDragMove: (drag, event) => 
        
        @moveBy drag.delta

    onDragStop: (drag) => @delete @drag.shift
    
    moveBy: (delta) ->

        if not @dotsel.rect?
            @dotsel.moveBy delta
            @update()

    # 0000000     0000000   000000000   0000000  00000000  000      
    # 000   000  000   000     000     000       000       000      
    # 000   000  000   000     000     0000000   0000000   000      
    # 000   000  000   000     000          000  000       000      
    # 0000000     0000000      000     0000000   00000000  0000000  

    onDotSel: (action, dots, dot) =>

        return if @dotsel.rect?
        
        switch action
            when 'set'          then @setDots  dots
            when 'add'          then @addDot   dots, dot
            when 'del'          then @delDot   dots, dot
            when 'clear'        then @clear()
            when 'startRect'    then @clear()
            when 'endRect'      then @setDots dots
            when 'move'         then @update()

    empty: -> not @box
    clear: ->

        @g   = null
        @gg  = null
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

    # 0000000     0000000   000000000   0000000  
    # 000   000  000   000     000     000       
    # 000   000  000   000     000     0000000   
    # 000   000  000   000     000          000  
    # 0000000     0000000      000     0000000   

    setDots: (dots) ->

        if @validSelection()
            @createRect()
            
        @update()

    addDot: (dots, dot) ->

        if not @validSelection()
            return
            
        if dots.length == 2
            @createRect()

        @updateBox()

    delDot: (dots, dot) -> @update()

    validSelection: ->
        
        bb = @dotsel.bbox()
        scaleBox bb, @stage.zoom
        @dotsel.dots.length >= 2 and bb.width + bb.height > 30
    
    # 0000000     0000000   000   000
    # 000   000  000   000   000 000
    # 0000000    000   000    00000
    # 000   000  000   000   000 000
    # 0000000     0000000   000   000

    update: -> 

        if not @validSelection()
            @clear()
        else
            @updateBox()
    
    updateBox: ->
        
        return if not @gg?
            
        @gg.transform rotation:0
        @gg.transform x:0, y:0
        
        box = @dotsel.bbox()
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

module.exports = DotResizer

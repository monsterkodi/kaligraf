###
00000000   00000000   0000000  
000   000  000       000       
0000000    0000000   0000000   
000   000  000            000  
000   000  00000000  0000000   
###

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{ opposide, moveBox, zoomBox, scaleBox, boxCenter, boxOffset, boxPos, boxRelPos } = require '../utils'

Cursor = require '../cursor'
    
class Res

    constructor: (@kali, @name) ->

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
        @svg.viewbox @stage.svg.viewbox()
        @svg.addClass 'resSVG'
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

        box = @bbox()
        
        @gg = @svg.group()
        @gg.addClass 'resizerGroup'
        
        z = @stage.zoom
        
        @rect = @gg.rect().addClass 'resRect'
        @rect.attr width: box.width, height: box.height
        
        @rotKnob = @gg.circle(10/z,10/z)
        @rotKnob.addClass 'resCenter'
        @setRotationCorner 'center'

        @rotDrag['center'] = new drag
            target:  @rotKnob.node
            onMove:  @onRotKnobMove
            onStop:  @onRotKnobStop
        
        addBorder = (x, y, w, h, cursor, id) =>
            border = @gg.rect()
            border.x x
            border.y y
            border.width  w
            border.height h
            border.addClass 'resBorder'
            border.style cursor: cursor, 'stroke-width': 1/z
            @borderDrag[id] = new drag
                target:  border.node
                onStart: @onBorderStart
                onMove:  @onBorderMove
                onStop:  @onBorderStop
            @borderDrag[id].id = id

        addBorder box.x  - 20/z,  box.y,  20/z, box.h, 'ew-resize', 'left'
        addBorder box.x2, box.y,  20/z, box.h, 'ew-resize', 'right'
        addBorder box.x,  box.y - 20/z,  box.w, 20/z, 'ns-resize', 'top'
        addBorder box.x,  box.y2, box.w, 20/z, 'ns-resize', 'bot'

        addCorner = (cx, cy, cursor, id) =>
            corner = @gg.rect(20/z,20/z).addClass 'resCorner'
            corner.cx cx
            corner.cy cy
            corner.style cursor: cursor, 'stroke-width': 1/z
            @cornerDrag[id] = new drag
                target:  corner.node
                onStart: @onCornerStart
                onMove:  @onCornerMove
                onStop:  @onCornerStop
            @cornerDrag[id].id = id
            
        addCorner box.x  - 10/z, box.y  - 10/z, 'nw-resize', 'top left'  
        addCorner box.x2 + 10/z, box.y  - 10/z, 'ne-resize', 'top right' 
        addCorner box.x2 + 10/z, box.y2 + 10/z, 'se-resize', 'bot right' 
        addCorner box.x  - 10/z, box.y2 + 10/z, 'sw-resize', 'bot left'  

        addCorner box.x  - 10/z, box.cy,        'ew-resize', 'left' 
        addCorner box.x2 + 10/z, box.cy,        'ew-resize', 'right'
        addCorner box.cx,        box.y  - 10/z, 'ns-resize', 'top'  
        addCorner box.cx,        box.y2 + 10/z, 'ns-resize', 'bot'  
        
        addRot = (cx, cy, id) =>
            rot = @gg.circle(14/z).addClass 'resRot'
            rot.cx cx
            rot.cy cy
            rot.style 'stroke-width': 1/z, cursor: Cursor.forTool 'rot ' + id
            @rotDrag[id] = new drag
                    target:  rot.node
                    onStart: @onRotStart
                    onMove:  @onRotMove
                    onStop:  @onRotStop
            @rotDrag[id].id = id
                   
        addRot box.x  - 7/z, box.y  - 7/z, 'top left'
        addRot box.x2 + 7/z, box.y  - 7/z, 'top right'
        addRot box.x  - 7/z, box.y2 + 7/z, 'bot left'
        addRot box.x2 + 7/z, box.y2 + 7/z, 'bot right'
 
        addRot box.x  - 7/z, box.cy,     'left'
        addRot box.x2 + 7/z, box.cy,     'right'
        addRot box.cx,       box.y  - 7/z, 'top'
        addRot box.cx,       box.y2 + 7/z, 'bot'        
        
        @drag = new drag
            target:  @rect.node
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
            @svg?.removeClass 'resInactive'
        else
            @drag?.deactivate()
            @svg?.addClass 'resInactive'

    # 00000000    0000000   000000000      000   0000000  000  0000000  00000000
    # 000   000  000   000     000        000   000       000     000   000
    # 0000000    000   000     000       000    0000000   000    000    0000000
    # 000   000  000   000     000      000          000  000   000     000
    # 000   000   0000000      000     000      0000000   000  0000000  00000000

    onCornerStart: (drag, event) => @onSizeStart drag, event
    onCornerMove:  (drag, event) => @onResize    drag, event
    onCornerStop:  (drag, event) => @onSizeStop  drag, event
    onBorderStart: (drag, event) => @onSizeStart drag, event
    onBorderMove:  (drag, event) => @onResize    drag, event
    onBorderStop:  (drag, event) => @onSizeStop  drag, event
    onRotMove:     (drag, event) => @onRotation  drag, event
    
    onSizeStart: (drag, event) => @onRotStart drag, event
    
    onRotStart: (drag, event) =>
        
        @onStart()
        if event.ctrlKey
            @setRotationCorner 'center'
        else
            @setRotationCorner drag.id

    onSizeStop: (drag, event) => 

        @kali.tool('snap').clear()
        @update()
            
    onRotStop: (drag, event) => 
        
        @update()
        @setRotationCorner 'center'
                    
    setRotationCorner: (@rotationCorner) ->
            
        if @rotationCorner == 'center'
            
            if @customCenter
                @setRotationCenter @customCenter, true
            else
                @setRotationCenter @calcCenter()
        else
            
            box = @bbox()
            center = boxPos box, opposide @rotationCorner
        
            @setRotationCenter center
        
    setRotationCenter: (@rotationCenter, custom) ->
        
        return if not @rotKnob?
        if custom
            @customCenter = @rotationCenter
            @rotKnob.addClass 'custom'
        else
            @rotKnob.removeClass 'custom'
            
        @rotKnob.cx @rotationCenter.x
        @rotKnob.cy @rotationCenter.y

    calcCenter: -> boxCenter @bbox()
                        
    onRotKnobMove: (drag, event) =>
            
        @setRotationCenter @stage.stageForEvent(pos event), true        

    didTransform: (transmat) -> 
        
        @gg.transform transmat
            
    onRotKnobStop: (drag, event) =>
        
        if drag.startPos == drag.lastPos
            delete @customCenter
            @setRotationCorner 'center'
                                    
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  

    moveBy: (delta) => 
        
        @gg?.dmove delta.x / @kali.stage.zoom, delta.y / @kali.stage.zoom
        
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

        @svg.viewbox @stage.svg.viewbox()
        
        if @empty()
            @clear()
        else
            @freshBox()
    
    reset: -> 
        
        @update()
        delete @customCenter
        @setRotationCorner 'center'
            
    freshBox: ->

        @clear()
        @createRect()
        
    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  

    onStage: (action, box) =>

        if action == 'viewbox' then @update()

module.exports = Res

###
000  000000000  00000000  00     00  00000000   00000000   0000000
000     000     000       000   000  000   000  000       000     
000     000     0000000   000000000  0000000    0000000   0000000 
000     000     000       000 0 000  000   000  000            000
000     000     00000000  000   000  000   000  00000000  0000000 
###

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{ opposide, itemIDs, boxPos } = require '../utils'

Res     = require './res'
SnapBox = require './snapbox'
    
class ItemRes extends Res

    constructor: (kali) ->

        super kali, 'ItemRes'
        
        post.on 'selection', @onSelection

    del: ->
        
        super()
        post.removeListener 'selection', @onSelection
        
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
        
        @didTransform transmat
        
        @done()
        
        post.emit 'resizer', 'rotation'
    
    #  0000000   000   000   0000000   000      00000000  
    # 000   000  0000  000  000        000      000       
    # 000000000  000 0 000  000  0000  000      0000000   
    # 000   000  000  0000  000   000  000      000       
    # 000   000  000   000   0000000   0000000  00000000  
    
    setAngle: (angle) ->
        
        @itemRotation = @getItemRotation()
        oldCenter = @rotationCenter
        @rotationCenter = boxPos @bbox(), opposide 'center'
        @doRotate angle - @angle()
        delete @itemRotation
        @rotationCenter = oldCenter
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

        box = @bbox()
        # if not event.metaKey
        if not event.ctrlKey
            sdelta = delta.times 1/@stage.zoom
            sdelta = @kali.tool('snap').delta sdelta, box:box, side:center, items:items
            delta  = sdelta.times @stage.zoom 
        else
            @kali.tool('snap').clear()
        
        if left then delta.x = -delta.x
        if top  then delta.y = -delta.y

        aspect = box.w / box.h
        
        if not event.shiftKey
            if Math.abs(delta.x) > Math.abs(delta.y)
                delta.y = delta.x / aspect
            else
                delta.x = delta.y * aspect

        if event.ctrlKey
            delta.x *= 2
            delta.y *= 2
            center = 'center'
            
        z  = @stage.zoom 
        sx = (box.w * z + delta.x)/(box.w * z)
        sy = (box.h * z + delta.y)/(box.h * z)
                
        transmat = new SVG.Matrix().around @rotationCenter.x, @rotationCenter.y, new SVG.Matrix().scale sx, sy

        @do 'resize'
                
        for item in items
            
            @trans.resize item, transmat, pos sx, sy
                        
        @selection.update()

        sx = @gg.transform().scaleX * sx
        sy = @gg.transform().scaleY * sy
        transmat = new SVG.Matrix().around @rotationCenter.x, @rotationCenter.y, new SVG.Matrix().scale sx, sy
        @didTransform transmat
        
        @done()
        
        post.emit 'resizer', 'resize'
        
    # 00000000  000   000  00000000  000   000  000000000   0000000    
    # 000       000   000  000       0000  000     000     000         
    # 0000000    000 000   0000000   000 0 000     000     0000000     
    # 000          000     000       000  0000     000          000    
    # 00000000      0      00000000  000   000     000     0000000     

    onRotStop: (drag, event) =>
        
        super drag, event
        
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

    bbox:  -> @selection.bbox()
    empty: -> @selection.empty()
    
    # 000  000000000  00000000  00     00   0000000
    # 000     000     000       000   000  000
    # 000     000     0000000   000000000  0000000
    # 000     000     000       000 0 000       000
    # 000     000     00000000  000   000  0000000

    setItems: (items)       -> @reset()
    addItem:  (items, item) -> @reset()
    delItem:  (items, item) -> @reset()
    
module.exports = ItemRes

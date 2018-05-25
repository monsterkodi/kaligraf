###
0000000     0000000   000000000  00000000   00000000   0000000
000   000  000   000     000     000   000  000       000     
000   000  000   000     000     0000000    0000000   0000000 
000   000  000   000     000     000   000  000            000
0000000     0000000      000     000   000  00000000  0000000 
###

{ elem, post, drag, first, last, pos, log, _ } = require 'kxk'

{ opposide, scaleBox, boxPos, boxRelPos } = require '../utils'

Res = require './res'
    
class DotRes extends Res

    constructor: (dotsel) ->
        
        super dotsel.kali, 'DotRes'
        @dotsel = dotsel
        post.on 'dotsel', @onDotSel

    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    del: ->
        
        super()
        
        post.removeListener 'dotsel', @onDotSel
        
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
        
        angle = Math.round angle if opt?.round
        
        doKey = 'rotate'+(@dotInfo.map (info) -> " #{info.dot.ctrl.index()}-#{info.dot.dot}").join ''

        @do doKey
        
        transmat = new SVG.Matrix().around @rotationCenter.x, @rotationCenter.y, new SVG.Matrix().rotate angle

        for {dot, center} in @dotInfo
            newCenter = pos new SVG.Point(center).transform transmat
            dot.cx newCenter.x
            dot.cy newCenter.y
            
        @dotsel.update()
          
        @didTransform transmat
        
        @done()

    setRotationCenter: (@rotationCenter, custom) ->

        super @rotationCenter, custom
        @customCenter = @rotationCenter
                
    calcCenter: -> @dotsel.center()
        
    #  0000000   000   000   0000000   000      00000000  
    # 000   000  0000  000  000        000      000       
    # 000000000  000 0 000  000  0000  000      0000000   
    # 000   000  000  0000  000   000  000      000       
    # 000   000  000   000   0000000   0000000  00000000  
    
    setAngle: (angle) ->
        
        @dotInfo = @getDotInfo
        oldCenter = @rotationCenter
        @rotationCenter = boxPos @bbox(), opposide 'center'
        @doRotate angle - @angle()
        @rotationCenter = oldCenter
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

        box = @bbox()
        aspect = box.w / box.h
        
        if not event.shiftKey
            if Math.abs(dx) > Math.abs(dy)
                dy = dx / aspect
            else
                dx = dy * aspect

        if event.ctrlKey
            dx *= 2
            dy *= 2
            center = 'center'
            
        sx = (box.w + dx) / box.w
        sy = (box.h + dy) / box.h
            
        resizeCenter = @rotationCenter
                
        transmat = new SVG.Matrix().around resizeCenter.x, resizeCenter.y, new SVG.Matrix().scale sx, sy

        @do 'resize'
                        
        for dot in @dotsel.dots
            
            oldCenter = @trans.getCenter dot
            newCenter = new SVG.Point oldCenter
            newCenter = newCenter.transform transmat
                
            dot.cx newCenter.x
            dot.cy newCenter.y
            
        @dotsel.update()
        
        sx = @gg.transform().scaleX * sx
        sy = @gg.transform().scaleY * sy
        transmat = new SVG.Matrix().around @rotationCenter.x, @rotationCenter.y, new SVG.Matrix().scale sx, sy
        @didTransform transmat
        
        @done()
        
    # 00000000  000   000  00000000  000   000  000000000   0000000  
    # 000       000   000  000       0000  000     000     000       
    # 0000000    000 000   0000000   000 0 000     000     0000000   
    # 000          000     000       000  0000     000          000  
    # 00000000      0      00000000  000   000     000     0000000   

    onRotStart: (drag, event) =>
        
        super drag, event
        
    onRotStop: (drag, event) => 
        
        super drag, event
        
        delete @dotInfo
        @setRotationCorner 'center'

    onStart: =>
        
        if @kali.shapeTool() != 'edit'
            @kali.tools.activateTool 'edit'
        
        @dotInfo = @getDotInfo()
                
    getDotInfo: ->
        
        @dotsel.dots.map (dot) => 
            dot:    dot
            center: @trans.center dot
        
    # 0000000    00000000    0000000    0000000
    # 000   000  000   000  000   000  000
    # 000   000  0000000    000000000  000  0000
    # 000   000  000   000  000   000  000   000
    # 0000000    000   000  000   000   0000000

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
            when 'endRect'      then @setDots  dots
            when 'add'          then @addDot   dots, dot
            when 'del'          then @delDot   dots, dot
            when 'clear'        then @clear()
            when 'startRect'    then @clear()
            when 'move'         then @update()

    bbox:  -> @dotsel.dotBox() 
    empty: -> @dotsel.empty() or @dotsel.dots.length < 2
            
    # 0000000     0000000   000000000   0000000  
    # 000   000  000   000     000     000       
    # 000   000  000   000     000     0000000   
    # 000   000  000   000     000          000  
    # 0000000     0000000      000     0000000   

    setDots: (dots) -> @reset()

    addDot: (dots, dot) ->

        if not @validSelection()
            return
            
        @reset()

    delDot: (dots, dot) -> @reset()
            
    validSelection: ->
        
        bb = @bbox()
        scaleBox bb, @stage.zoom
        @dotsel.dots.length >= 2 and bb.width + bb.height > 30
    
module.exports = DotRes

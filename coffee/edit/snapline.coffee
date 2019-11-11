###
 0000000  000   000   0000000   00000000   000      000  000   000  00000000
000       0000  000  000   000  000   000  000      000  0000  000  000     
0000000   000 0 000  000000000  00000000   000      000  000 0 000  0000000 
     000  000  0000  000   000  000        000      000  000  0000  000     
0000000   000   000  000   000  000        0000000  000  000   000  00000000
###

{ first, kpos, last } = require 'kxk'

{ uuid } = require '../utils'

Trans      = require '../trans'
SnapTarget = require './snaptarget'

class SnapLine

    constructor: (@kali, @box, @dot) ->
        
        stagePos = kpos @dot.cx(),@dot.cy()

        root = @box.doc()
        @line = root.line()
        @line.plot [[stagePos.x, stagePos.y], [stagePos.x, stagePos.y]]

        @line.style
            'pointer-events': 'none'
            fill:             'none'
            stroke:           @kali.tools.stroke.color
            'stroke-opacity': @kali.tools.stroke.alpha
            'stroke-width':   @kali.tools.width.width
            'fill-opacity':   0.0
            
        @line.data 'type', 'snapline'
        @line.data 'source-box',   @box.id()
        @line.data 'source-point', @dot.ctrl.itemPoint()[2]
        uuid @line
    
    @updateLineBox: (line, box, srcOrTgt) ->
        
        switch srcOrTgt
            when 'source'
                point = line.data 'source-point'
                SnapLine.setLineSourcePoint line, SnapLine.boxPoint box, point
            when 'target'
                point = line.data 'target-point'
                SnapLine.setLineTargetPoint line, SnapLine.boxPoint box, point
        
    @setLineSourcePoint: (line, stagePos) ->
        
        points = line.array?().valueOf() 
        firstPoint = first points
        firstPoint[0] = stagePos.x
        firstPoint[1] = stagePos.y
        line.plot points
        
    @setLineTargetPoint: (line, stagePos) ->
        
        points = line.array?().valueOf() 
        lastPoint = last points
        lastPoint[0] = stagePos.x
        lastPoint[1] = stagePos.y
        line.plot points
        
    @boxPoint: (box, point) ->
        
        r = first box.children()
        tpos = (x,y) -> Trans.fullTransform r, kpos xx,y
        switch point
            when 'top left'  then tpos 0,0
            when 'top'       then tpos r.width()/2, 0
            when 'top right' then tpos r.width(), 0
            when 'right'     then tpos r.width(), r.height()/2
            when 'bot right' then tpos r.width(), r.height()
            when 'bot'       then tpos r.width()/2, r.height()
            when 'bot left'  then tpos 0, r.height()
            when 'left'      then tpos 0, r.height()/2
            when 'center'    then tpos r.width()/2, r.height()/2
        
    onDrag: (drag, event) =>
        
        stagePos = @kali.stage.stageForEvent kpos eventevent
        
        if 'snapbox' == event.target?.instance?.parent()?.data? 'type'
            box = event.target.instance.parent()
        else if 'snapbox' == event.target?.parentNode?.instance?.parent()?.data? 'type'
            box = event.target.parentNode.instance.parent()
            
        if box
            SnapBox = require './snapbox'
            closest = SnapBox.closestTarget @kali, box, stagePos
            if not @target or @target.closest.point != closest.point
                @clearTarget()
                @target = new SnapTarget @kali, box, closest
        else if event.target.type == 'svg'
            @clearTarget()
        
        @setTargetPoint stagePos
        
    setTargetPoint: (stagePos) -> SnapLine.setLineTargetPoint @line, stagePos
        
    onDragStop: (drag, event) =>
        
        if @target and (@target.box != @box or @target.closest.point != @line.data 'source-point')
            @line.remove()
            @target?.del()
            @kali.stage.do "snapline#{@line.id()}"
            @line.addTo @box.doc()
            @setTargetPoint @target.closest.pos
            @line.data 'target-box',   @target.box.id()
            @line.data 'target-point', @target.closest.point
            delete @target
            @kali.stage.done()
        else
            @clearTarget()
            @line.remove()

    clearTarget: ->
        
        @target?.del()
        delete @target
            
module.exports = SnapLine

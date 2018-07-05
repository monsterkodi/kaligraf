###
 0000000  000   000   0000000   00000000   000      000  000   000  00000000
000       0000  000  000   000  000   000  000      000  0000  000  000     
0000000   000 0 000  000000000  00000000   000      000  000 0 000  0000000 
     000  000  0000  000   000  000        000      000  000  0000  000     
0000000   000   000  000   000  000        0000000  000  000   000  00000000
###

{ last, pos, log, _ } = require 'kxk'

{ uuid } = require '../utils'

SnapTarget = require './snaptarget'

class SnapLine

    constructor: (@kali, @box, @dot) ->
        
        stagePos = pos @dot.cx(), @dot.cy()

        root = @box.doc()
        @line = root.line()
        @line.plot [[stagePos.x, stagePos.y], [stagePos.x, stagePos.y]]

        @line.style
            'pointer-events': 'none'
            stroke:           @kali.tools.stroke.color
            'stroke-opacity': @kali.tools.stroke.alpha
            'stroke-width':   @kali.tools.width.width
            fill:             'none'
            'fill-opacity':   0.0
            
        @line.data 'type', 'snapline'
        @line.data 'source-box',   @box.id()
        @line.data 'source-point', @dot.ctrl.itemPoint()[2]
        uuid @line
    
    onDrag: (drag, event) =>
        
        stagePos = @kali.stage.stageForEvent pos event
        
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
        
    setTargetPoint: (stagePos) ->
        
        points = @line.array?().valueOf() 
        lastPoint = last points
        lastPoint[0] = stagePos.x
        lastPoint[1] = stagePos.y
                
        @line.plot points
        
    onDragStop: (drag, event) =>
        
        if @target
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
            @line.remove()

    clearTarget: ->
        @target?.del()
        delete @target
            
module.exports = SnapLine

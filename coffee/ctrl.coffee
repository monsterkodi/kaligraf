
#  0000000  000000000  00000000   000
# 000          000     000   000  000
# 000          000     0000000    000
# 000          000     000   000  000
#  0000000     000     000   000  0000000

{ drag, last, pos, log, _ } = require 'kxk'

class Ctrl

    constructor: (@object) ->

        @dots  = {}
        @lines = {}
        @drags = []

        @edit  = @object.edit
        @stage = @edit.stage
        @trans = @edit.trans

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        for d in @drags
            d.deactivate()

        for k,d of @dots
            d.remove()

        for k,l of @lines
            l.remove()

        @dots  = {}
        @lines = {}
        @drags = []

    # 0000000     0000000   000000000
    # 000   000  000   000     000
    # 000   000  000   000     000
    # 000   000  000   000     000
    # 0000000     0000000      000

    #  0000000  00000000   00000000   0000000   000000000  00000000  
    # 000       000   000  000       000   000     000     000       
    # 000       0000000    0000000   000000000     000     0000000   
    # 000       000   000  000       000   000     000     000       
    #  0000000  000   000  00000000  000   000     000     00000000  
    
    createDot: (type) ->

        if @object.isPoly()
            s = @edit.dotSize/2
            dot = @edit.svg.polygon [[0,s], [s,0], [0,-s], [-s,0]]
        else if @pointType() in ['L', 'M']
            dot = @edit.svg.rect @edit.dotSize, @edit.dotSize 
        else
            dot = @edit.svg.circle @edit.dotSize 
        dot.addClass 'editDot'
        dot.addClass "#{type}Dot"
        dot.style cursor: 'pointer'

        @dots[type] = dot

        if type in ['ctrl1', 'ctrl2', 'ctrlr', 'ctrlq']
            @createLine type
        if type == 'ctrlq'
            @createLine 'ctrlq2'

        @drags.push new drag
            target:  dot.node
            onStart: @onStart
            onMove:  @onMove
            onStop:  @onStop

        last(@drags).type = type

        dot

    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    updateDot: (type, point) ->
        
        dot = @dots[type]
        
        if not dot?
            log 'updateDot no dot?', type
            return
        
        itemPos = switch type
            when 'ctrl1', 'ctrlq' then pos point[1], point[2]
            when 'ctrl2'          then pos point[3], point[4]
            when 'ctrlr'          
                pp = pos point[point.length-2], point[point.length-1]
                cp = pos point[1], point[2]
                pp.minus pp.to cp 
            when 'point'
                if _.isString point[0]
                    pos point[point.length-2], point[point.length-1]
                else
                    pos point[0], point[1]
        
        dotPos = @stage.viewForStage @trans.transform @object.item, itemPos
        
        dot.cx dotPos.x
        dot.cy dotPos.y

        if type in ['ctrl1', 'ctrl2', 'ctrlr', 'ctrlq']
            pointPos = @stage.viewForStage @trans.transform @object.item, pos point[point.length-2], point[point.length-1]
            @plotLine type, dotPos, pointPos
            
            if type == 'ctrlq'
                point2 = @object.dotPos @index()-1
                @plotLine 'ctrlq2', dotPos, point2
        
    # 000      000  000   000  00000000
    # 000      000  0000  000  000
    # 000      000  000 0 000  0000000
    # 000      000  000  0000  000
    # 0000000  000  000   000  00000000

    createLine: (type) ->

        line = @edit.svg.line()
        line.addClass "editLine"
        line.addClass "#{type}Line"
        line.back()

        @lines[type] = line
        
        line = @edit.svg.line()
        line.addClass "editLine"
        line.addClass "#{type}_Line"
        line.back()
        
        @lines["#{type}_"] = line
        
    plotLine: (type, pos1, pos2) ->
        
        @lines[type    ]?.plot [[pos1.x, pos1.y], [pos2.x, pos2.y]]
        @lines[type+'_']?.plot [[pos1.x, pos1.y], [pos2.x, pos2.y]]
        
    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    onStart: (drag, event) =>
    onStop:  (drag, event) =>
    onMove:  (drag, event) =>

        index = @index()
        viewPos = @stage.viewForEvent pos event
        types = [drag.type]

        @object.movePoint index, viewPos, types
        
        if @object.isPath() and drag.type == 'point' and not event.shiftKey
            
            moveDelta = (ctrl) =>
                dotPos = @object.dotPos index, ctrl
                newPos = dotPos.plus drag.delta
                @object.movePoint index, newPos, [ctrl]
            
            code = @pointType()
            if code in ['S', 'C'] then moveDelta 'ctrl1'
            if code == 'C'        then moveDelta 'ctrl2'
            else if code == 'Q'   then moveDelta 'ctrlq'
        
        @object.plot()

    moveBy: (delta) -> 

        for k,dot of @dots
            dot.cx dot.cx() + delta.x
            dot.cy dot.cy() + delta.y

        for k,line of @lines
            line.cx line.cx() + delta.x
            line.cy line.cy() + delta.y
            
    # 00000000    0000000   000  000   000  000000000
    # 000   000  000   000  000  0000  000     000
    # 00000000   000   000  000  000 0 000     000
    # 000        000   000  000  000  0000     000
    # 000         0000000   000  000   000     000

    index:     -> @object.ctrls.indexOf @
    itemPoint: -> @object.points()[@index()]
    pointType: ->
        if @object.isPoly()
            'P'
        else
            @itemPoint()[0]

module.exports = Ctrl

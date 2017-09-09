
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

    createDot: (type, stagePos) ->

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

        if type in ['ctrl1', 'ctrlr', 'ctrl2']
            @createLine type

        @drags.push new drag
            target:  dot.node
            onStart: @onStart
            onMove:  @onMove
            onStop:  @onStop

        last(@drags).type = type

        dot

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
        
        if type in ['ctrl1', 'ctrl2', 'ctrlr']
            @createLine "#{type}_"

    updateLine: (type) ->

        if line = @lines[type]
            cpos = @stage.viewForStage @getPos type
            ppos = @stage.viewForStage @getPos 'point'
            line.plot [[ppos.x, ppos.y], [cpos.x, cpos.y]]
            
            if type in ['ctrl1', 'ctrl2', 'ctrlr']
                @lines["#{type}_"].plot [[ppos.x, ppos.y], [cpos.x, cpos.y]]
                
        else if type == 'point'
            @updateLine 'ctrl1'
            @updateLine 'ctrl2'
            @updateLine 'ctrlr'

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    onStart: (drag, event) =>
    onStop:  (drag, event) =>
    onMove:  (drag, event) =>

        stagePos = @stage.stageForEvent pos event

        type = drag.type

        @setPos type, stagePos, not event.shiftKey
        # log "onMove #{type} index:#{@index()} ", stagePos, @object.item.array().valueOf()
        @object.plot()

    moveBy: (delta) -> @setPos 'point', @getPos('point').plus(delta), true

    # 00000000    0000000   000  000   000  000000000
    # 000   000  000   000  000  0000  000     000
    # 00000000   000   000  000  000 0 000     000
    # 000        000   000  000  000  0000     000
    # 000         0000000   000  000   000     000

    index:     -> @object.ctrls.indexOf @
    itemPoint: -> @object.item.array().valueOf()[@index()]
    pointType: ->
        if @object.isPoly()
            'P'
        else
            @itemPoint()[0]

    # 00000000    0000000    0000000
    # 000   000  000   000  000
    # 00000000   000   000  0000000
    # 000        000   000       000
    # 000         0000000   0000000

    getPos: (type) ->

        if dot = @dots[type] ? @lines[type]
            @getDotPos dot

    setPos: (type, stagePos, moveAll) ->

        dot = @dots[type]

        if not dot?
            log 'no dot?', type
            return

        oldPos = @getPos 'point'

        @setDotPos dot, stagePos

        @setSmoothPos type
        @updateLine   type
        @setItemPos   type, @trans.inverse @object.item, stagePos

        if moveAll and type == 'point' and @dots['ctrl1']
            @setPos 'ctrl1', @getPos('ctrl1').plus oldPos.to stagePos

    # 0000000     0000000   000000000  00000000    0000000    0000000
    # 000   000  000   000     000     000   000  000   000  000
    # 000   000  000   000     000     00000000   000   000  0000000
    # 000   000  000   000     000     000        000   000       000
    # 0000000     0000000      000     000         0000000   0000000

    setDotPos: (dot, stagePos) ->

        viewPos = @stage.viewForStage stagePos
        dot.cx viewPos.x
        dot.cy viewPos.y

    getDotPos: (dot) ->

        @stage.stageForView pos dot.cx(), dot.cy()

    updatePos: ->

        for type,dot of @dots
            @setDotPos dot, @trans.transform @object.item, @getItemPos type
            
        @setSmoothPos 'point'
        @updateLine 'ctrl1'
        @updateLine 'ctrl2'
            
    #  0000000  00     00   0000000    0000000   000000000  000   000
    # 000       000   000  000   000  000   000     000     000   000
    # 0000000   000000000  000   000  000   000     000     000000000
    #      000  000 0 000  000   000  000   000     000     000   000
    # 0000000   000   000   0000000    0000000      000     000   000

    setSmoothPos: (type) ->

        switch type
            when 'ctrl1', 'point' then sibling = 'ctrlr'
            when 'ctrlr'          then sibling = 'ctrl1'
            else
                return

        if dot = @dots[sibling]

            @setDotPos  dot, @object.reflPos @index(), sibling
            @updateLine sibling

    # 000  000000000  00000000  00     00  
    # 000     000     000       000   000  
    # 000     000     0000000   000000000  
    # 000     000     000       000 0 000  
    # 000     000     00000000  000   000  

    setItemPos: (type, itemPos) ->

        if @object.isPoly()

            @setPolyPos type, itemPos

        else

            switch type

                when 'point'          then @setPointPos type, itemPos
                when 'ctrl1', 'ctrl2' then @setCtrlPos  type, itemPos
                when 'ctrlr'
                    stageRefl = @object.reflPos @index(), 'ctrl1'
                    refl = @trans.inverse @object.item, stageRefl
                    @setCtrlPos  'ctrl1', refl

    getItemPos: (type) ->

        if @object.isPoly()

            @getPolyPos type

        else

            switch type

                when 'point'          then @getPointPos type
                when 'ctrl1', 'ctrl2' then @getCtrlPos  type
                when 'ctrlr'
                    stageRefl = @object.reflPos @index(), 'ctrl1'
                    @trans.inverse @object.item, stageRefl

    # 00000000    0000000   000      000   000
    # 000   000  000   000  000       000 000
    # 00000000   000   000  000        00000
    # 000        000   000  000         000
    # 000         0000000   0000000     000

    getPolyPos: (type) ->

        point = @itemPoint()
        pos point[0], point[1]
    
    setPolyPos: (type, itemPos) ->
        
        if @object.item.type == 'line'
            points = @object.points()
            point  = points[@index()]
            point[0] = itemPos.x
            point[1] = itemPos.y            
            @object.item.plot points
        else
            point    = @itemPoint()
            point[0] = itemPos.x
            point[1] = itemPos.y            

    #  0000000  000000000  00000000   000
    # 000          000     000   000  000
    # 000          000     0000000    000
    # 000          000     000   000  000
    #  0000000     000     000   000  0000000

    getCtrlPos:  (type) ->

        point = @itemPoint()

        if point[0] in ['C', 'c', 'S', 's', 'Q', 'q']

            pos point[1], point[2]

    setCtrlPos:  (type, itemPos) ->

        return if not itemPos?

        point = @itemPoint()

        if point[0] in ['C', 'c', 'S', 's', 'Q', 'q']

            point[1] = itemPos.x
            point[2] = itemPos.y

    # 00000000    0000000   000  000   000  000000000
    # 000   000  000   000  000  0000  000     000
    # 00000000   000   000  000  000 0 000     000
    # 000        000   000  000  000  0000     000
    # 000         0000000   000  000   000     000

    getPointPos: (type) ->

        point = @itemPoint()

        if point[0] in ['C', 'c', 'S', 's', 'Q', 'q', 'M', 'm', 'L', 'l']

            pos point[point.length-2], point[point.length-1]
            
    setPointPos: (type, itemPos) ->

        point = @itemPoint()

        if point[0] in ['C', 'c', 'S', 's', 'Q', 'q', 'M', 'm', 'L', 'l']

            point[point.length-2] = itemPos.x
            point[point.length-1] = itemPos.y

module.exports = Ctrl

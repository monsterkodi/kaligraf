
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
    
    createDot: (dot) ->

        if @object.isPoly()
            s = @edit.dotSize/2
            svg = @edit.svg.polygon [[0,s], [s,0], [0,-s], [-s,0]]
        else if @pointCode() in ['L', 'M']
            svg = @edit.svg.rect @edit.dotSize, @edit.dotSize 
        else
            svg = @edit.svg.circle @edit.dotSize 
        svg.addClass 'editDot'
        svg.addClass "#{dot}Dot"
        svg.style cursor: 'pointer'
        svg.ctrl = @
        svg.dot  = dot

        @dots[dot] = svg

        if dot in ['ctrl1', 'ctrl2', 'ctrlq', 'ctrlr', 'ctrls']
            @createLine dot
        if dot == 'ctrlq'
            @createLine 'ctrlq2'

        @drags.push new drag
            target:  svg.node
            onStart: @onStart
            onMove:  @onMove
            onStop:  @onStop

        last(@drags).dot = dot

        svg

    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    updateDot: (dot, point) ->
        
        svg = @dots[dot]
        
        if not svg?
            log 'updateDot no svg?', dot
            return
        
        itemPos = switch dot
            when 'ctrl1', 'ctrlq', 'ctrls' then pos point[1], point[2]
            when 'ctrl2'                   then pos point[3], point[4]
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
        
        svg.cx dotPos.x
        svg.cy dotPos.y

        pointPos = @stage.viewForStage @trans.transform @object.item, pos point[point.length-2], point[point.length-1]
        
        if dot in ['ctrl2', 'ctrls', 'ctrlr', 'ctrlq']
            @plotLine dot, dotPos, pointPos
            
        if dot == 'ctrl1'
            prevPoint = @object.dotPos @index()-1
            @plotLine 'ctrl1', dotPos, prevPoint
        else if dot == 'ctrlq'
            prevPoint = @object.dotPos @index()-1
            @plotLine 'ctrlq2', dotPos, prevPoint
        
    # 000      000  000   000  00000000
    # 000      000  0000  000  000
    # 000      000  000 0 000  0000000
    # 000      000  000  0000  000
    # 0000000  000  000   000  00000000

    createLine: (dot) ->

        line = @edit.svg.line()
        line.addClass "editLine"
        line.addClass "#{dot}Line"
        line.back()

        @lines[dot] = line
        
        line = @edit.svg.line()
        line.addClass "editLine"
        line.addClass "#{dot}_Line"
        line.back()
        
        @lines["#{dot}_"] = line
        
    plotLine: (dot, pos1, pos2) ->
        
        @lines[dot    ]?.plot [[pos1.x, pos1.y], [pos2.x, pos2.y]]
        @lines[dot+'_']?.plot [[pos1.x, pos1.y], [pos2.x, pos2.y]]

    #  0000000  00000000  000      00000000   0000000  000000000  00000000  0000000    
    # 000       000       000      000       000          000     000       000   000  
    # 0000000   0000000   000      0000000   000          000     0000000   000   000  
    #      000  000       000      000       000          000     000       000   000  
    # 0000000   00000000  0000000  00000000   0000000     000     00000000  0000000    
    
    setSelected: (dot, selected) ->
        
        if selected
            @dots[dot].addClass 'selected'
        else
            @dots[dot].removeClass 'selected'
            
    isSelected: (dot) -> @dots[dot].hasClass 'selected'
        
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    onStart: (drag, event) =>

        @wasSelected = @isSelected drag.dot
        @object.edit.dotsel.add @dots[drag.dot], true
                
    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onStop: (drag, event) =>
        
        if drag.startPos == drag.lastPos
            if @wasSelected and event.shiftKey
                @object.edit.dotsel.del @dots[drag.dot]
            else
                @object.edit.dotsel.add @dots[drag.dot], event.shiftKey
        delete @wasSelected

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    onMove: (drag, event) =>

        if @object.edit.selectedDots.length > 1
            @object.edit.moveDotsBy drag.delta
            return
        
        index   = @index()
        viewPos = @stage.viewForEvent pos event

        @object.movePoint index, viewPos, drag.dot
        
        if @object.isPath() and drag.dot == 'point' and not event.shiftKey
            
            moveDelta = (ctrl) =>
                dotPos = @object.dotPos index, ctrl
                newPos = dotPos.plus drag.delta
                @object.movePoint index, newPos, ctrl
            
            switch @pointCode()
                when 'S' then moveDelta 'ctrls'
                when 'Q' then moveDelta 'ctrlq'
                when 'C' then moveDelta 'ctrl1'; moveDelta 'ctrl2'
        
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
    pointCode: ->
        if @object.isPoly()
            'P'
        else
            @itemPoint()[0]

module.exports = Ctrl

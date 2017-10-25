###
 0000000   0000000          000  00000000   0000000  000000000
000   000  000   000        000  000       000          000
000   000  0000000          000  0000000   000          000
000   000  000   000  000   000  000       000          000
 0000000   0000000     0000000   00000000   0000000     000
###

{ post, empty, last, pos, log, _ } = require 'kxk'

{ itemGradient, itemMatrix } = require '../utils'

Ctrl   = require './ctrl'
Gradi  = require './gradi'
Points = require './points'

class Object extends Points

    constructor: (@edit, @item) ->

        super @edit.kali, @item
        
        @name  = "Object-#{@item.id()}" 
        @svg   = @edit.svg
        @kali  = @edit.kali
        @trans = @kali.trans
        @stage = @kali.stage
        
        @ctrls = []
        
        @initItem()

    do:   (action) -> @stage.undo.do @, action
    done:          -> @stage.undo.done   @

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        for ctrl in @ctrls
            ctrl.del()
            
        for k,gradi of @gradi
            gradi.del()

        @ctrls = []

    #  0000000  00000000  000000000     000  000000000  00000000  00     00
    # 000       000          000        000     000     000       000   000
    # 0000000   0000000      000        000     000     0000000   000000000
    #      000  000          000        000     000     000       000 0 000
    # 0000000   00000000     000        000     000     00000000  000   000

    initItem: ->

        if points = @points()

            for i in [0...points.length]
                
                @initCtrlDots   i, points[i]
                @updateCtrlDots i, points[i]
                
            for i in [0...points.length]
                if points[i][0] =='M'
                    @ctrls[i].dots.point.front()
            
        for style in ['stroke', 'fill']
            if gradient = itemGradient @item, style
                @addGradi style
                
    addGradi: (style) ->
                
        @gradi ?= {}
        if not @gradi[style]?
            @gradi[style] = new Gradi @, style

        @gradi[style].update()

    updateGradi: (style, info) -> @gradi?[style]?.update()
        
    # 000  000   000  000  000000000  0000000     0000000   000000000   0000000
    # 000  0000  000  000     000     000   000  000   000     000     000
    # 000  000 0 000  000     000     000   000  000   000     000     0000000
    # 000  000  0000  000     000     000   000  000   000     000          000
    # 000  000   000  000     000     0000000     0000000      000     0000000

    initCtrlDots: (index, point) ->

        if index < @ctrls.length
            ctrl = @ctrls[index]
        else
            ctrl = new Ctrl @
            @ctrls.push ctrl

        ctrl.initDots point
        ctrl

    # 000   000  00000000   0000000     0000000   000000000  00000000
    # 000   000  000   000  000   000  000   000     000     000
    # 000   000  00000000   000   000  000000000     000     0000000
    # 000   000  000        000   000  000   000     000     000
    #  0000000   000        0000000    000   000     000     00000000

    updateCtrlDots: (index, point) ->

        @ctrls[index].updateDots point

    updateCtrlLines: (index, point) ->

        @ctrls[index].updateLines point

    updatePos: ->

        points = @points()

        for i in [0...points.length]

            @updateCtrlDots i, points[i]

    # 00     00   0000000   000   000  00000000  0000000     0000000   000000000   0000000
    # 000   000  000   000  000   000  000       000   000  000   000     000     000
    # 000000000  000   000   000 000   0000000   000   000  000   000     000     0000000
    # 000 0 000  000   000     000     000       000   000  000   000     000          000
    # 000   000   0000000       0      00000000  0000000     0000000      000     0000000

    moveDotsBy: (dots, delta, event) ->
        
        @moveIndexDots indexDots:@indexDots(dots), delta:delta, event:event

        if points = @points()

            for i in [0...points.length]
                
                @updateCtrlDots i, points[i]
        
    #  0000000  00000000  000000000  00000000    0000000   000  000   000  000000000
    # 000       000          000     000   000  000   000  000  0000  000     000
    # 0000000   0000000      000     00000000   000   000  000  000 0 000     000
    #      000  000          000     000        000   000  000  000  0000     000
    # 0000000   00000000     000     000         0000000   000  000   000     000

    setPoint: (index, dot, itemPos) ->

        super index, dot, itemPos
        
        point = @points()[index]
        
        @updateCtrlLines index, point
        
        if point[0] in ['Q', 'M', 'L', 'C'] and index < @numPoints()-1
            @updateCtrlLines index+1, @pointAt index+1

    #  0000000  000000000  00000000    0000000   000   0000000   000   000  000000000  00000000  000   000  
    # 000          000     000   000  000   000  000  000        000   000     000     000       0000  000  
    # 0000000      000     0000000    000000000  000  000  0000  000000000     000     0000000   000 0 000  
    #      000     000     000   000  000   000  000  000   000  000   000     000     000       000  0000  
    # 0000000      000     000   000  000   000  000   0000000   000   000     000     00000000  000   000  
    
    straightenDot: (index, dot) ->
        
        previ = index-1
        previ = @numPoints()-1 if previ == 0

        switch dot
            when 'ctrlq'
                @straighten index, 'prev'
                @straighten previ, 'next'
            when 'ctrlr' then
            when 'ctrls'
                @straighten index, 'prev'
            when 'ctrl1'
                @straighten previ, 'next'
            when 'ctrl2'
                @straighten index, 'prev'
            when 'point'
                @straighten index, 'none'
                
        @edit.update()
            
    # 000   000  00000000   0000000     0000000   000000000  00000000  0000000     0000000   000000000   0000000
    # 000   000  000   000  000   000  000   000     000     000       000   000  000   000     000     000
    # 000   000  00000000   000   000  000000000     000     0000000   000   000  000   000     000     0000000
    # 000   000  000        000   000  000   000     000     000       000   000  000   000     000          000
    #  0000000   000        0000000    000   000     000     00000000  0000000     0000000      000     0000000

    updateDots: (dots) ->

        for dot in dots

            index   = dot.ctrl.index()
            itemPos = @dotPos index, dot.dot
            itemPos = @trans.fullInverse dot.ctrl.object.item, itemPos
            @setPoint index, itemPos, dot.dot

        @applyPoints()
        
    #  0000000   0000000    0000000    00000000    0000000   000  000   000  000000000
    # 000   000  000   000  000   000  000   000  000   000  000  0000  000     000
    # 000000000  000   000  000   000  00000000   000   000  000  000 0 000     000
    # 000   000  000   000  000   000  000        000   000  000  000  0000     000
    # 000   000  0000000    0000000    000         0000000   000  000   000     000

    addPoint: (index, stagePos, code) ->

        itemPos = @trans.inverse @item, stagePos

        points = @points()
        point = switch code
            when 'Q'
                @adjustLastQuadDot()
                [code, stagePos.x, stagePos.y, stagePos.x, stagePos.y]
            when 'S'
                [code, stagePos.x, stagePos.y, stagePos.x, stagePos.y]
            when 'C'
                [code, stagePos.x, stagePos.y, stagePos.x, stagePos.y, stagePos.x, stagePos.y]
            else
                [itemPos.x, itemPos.y]

        points.splice index, 0, point

        @initCtrlDots   index, point
        @updateCtrlDots index, point

    isClosed: ->
        
        @posAt(0).to(@posAt @numPoints()-1).length() < 0.0001
        
    adjustLastQuadDot: ->
        
        points = @points()
        lastPoint = last points
        prevPos = @posAt points.length-2
        if lastPoint[1] == prevPos.x and lastPoint[2] == prevPos.y
            midPos = prevPos.mid @posAt points.length-1
            lastPoint[1] = midPos.x
            lastPoint[2] = midPos.y
            @updateCtrlDots points.length-1, lastPoint
        
    # 0000000    00000000  000      00000000    0000000   000  000   000  000000000
    # 000   000  000       000      000   000  000   000  000  0000  000     000
    # 000   000  0000000   000      00000000   000   000  000  000 0 000     000
    # 000   000  000       000      000        000   000  000  000  0000     000
    # 0000000    00000000  0000000  000         0000000   000  000   000     000

    delPoint: (index) ->

        @ctrls[index].del()
        @ctrls.splice index, 1
        points = @points()
        points.splice index, 1

        if empty points
            @edit.delItem @item
        else
            @applyPoints()
            @updateCtrlDots index,   @pointAt index   if index < @numPoints()
            @updateCtrlDots index+1, @pointAt index+1 if index < @numPoints()-1

    # 0000000    00000000  000      0000000     0000000   000000000
    # 000   000  000       000      000   000  000   000     000
    # 000   000  0000000   000      000   000  000   000     000
    # 000   000  000       000      000   000  000   000     000
    # 0000000    00000000  0000000  0000000     0000000      000

    delDots: (dots) ->

        for indots in @indexDots dots
            @delIndexDots indots.index, indots.dots

    delIndexDots: (index, dots) ->

        if 'point' in dots
            @delPoint index
            return

        points = @points()
        point = points[index]

        if dots.length > 1
            if 'ctrl1' in dots and 'ctrl2' in dots
                point[0] = 'L'
                point.splice 1, 4
            else if 'ctrlr' in dots
                point[0] = 'L'
                point.splice 1, 2
            else
                log '???', dots
        else
            switch dots[0]
                when 'ctrlq', 'ctrls', 'ctrlr'
                    point[0] = 'L'
                    point.splice 1, 2
                when 'ctrl1'
                    point[0] = 'Q'
                    point.splice 1,2
                when 'ctrl2'
                    point[0] = 'Q'
                    point.splice 3,2

        @initCtrlDots   index, point
        @updateCtrlDots index, point
        @applyPoints()
        @updateCtrlDots index+1, @pointAt index+1 if index < @numPoints()-1

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveCtrlsBy: (delta) ->

        for ctrl in @ctrls
            ctrl.moveBy delta.times 1.0/@kali.stage.zoom

    # 0000000     0000000   000000000   0000000  
    # 000   000  000   000     000     000       
    # 000   000  000   000     000     0000000   
    # 000   000  000   000     000          000  
    # 0000000     0000000      000     0000000   
    
    dots: ->
        
        dots = []
        for ctrl in @ctrls
            dots = dots.concat _.values ctrl.dots
        dots

    nextDot: (dot) ->
        
        index = dot.ctrl.index()
        nexti = index+1
        nexti = 0 if nexti >= @numPoints()
        @ctrls[nexti].dots.point
        
    prevDot: (dot) ->
        
        index = dot.ctrl.index()
        previ = index-1
        previ = @numPoints()-1 if previ < 0
        @ctrls[previ].dots.point
        
    indexDots: (dots) ->

        indexDots = []
        for index in [@numPoints()-1..0]
            idots = dots.filter (dot) -> dot.ctrl?.index() == index
            if not empty idots
                indexDots.push index:index, dots:idots.map (dot) -> dot.dot
        indexDots

    dotPos: (index, dot='point') ->

        if d = @ctrlAt(index)?.dots[dot]
            pos d.cx(), d.cy()
        else
            log "no dot #{dot} at index #{index}?"

    ctrlAt: (index) -> 
        if index in ['fill', 'stroke']
            return gradi?[index]
        @ctrls[@index index]
        
module.exports = Object

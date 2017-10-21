
#  0000000   0000000          000  00000000   0000000  000000000
# 000   000  000   000        000  000       000          000
# 000   000  0000000          000  0000000   000          000
# 000   000  000   000  000   000  000       000          000
#  0000000   0000000     0000000   00000000   0000000     000

{ post, empty, last, pos, log, _ } = require 'kxk'

{ itemGradient, itemMatrix } = require '../utils'

Ctrl  = require './ctrl'
Gradi = require './gradi'
Mover = require './mover'

class Object

    constructor: (@edit, item) ->

        @name  = "Object-#{item.id()}" 
        @svg   = @edit.svg
        @kali  = @edit.kali
        @trans = @kali.trans
        @stage = @kali.stage

        @ctrls = []

        if item? then @setItem item

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

    setItem: (item) ->

        @del()

        @item = item

        if points = @points()

            # log 'Object.setItem', item.type, points, itemMatrix item
            
            for i in [0...points.length]
                
                @initCtrlDots   i, points[i]
                @updateCtrlDots i, points[i]
            
        for style in ['stroke', 'fill']
            if gradient = itemGradient item, style
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
        
        new Mover @, indexDots:@indexDots(dots), delta:delta, event:event

        if points = @points()

            for i in [0...points.length]
                
                @updateCtrlDots i, points[i]
        
    #  0000000  00000000  000000000  00000000    0000000   000  000   000  000000000
    # 000       000          000     000   000  000   000  000  0000  000     000
    # 0000000   0000000      000     00000000   000   000  000  000 0 000     000
    #      000  000          000     000        000   000  000  000  0000     000
    # 0000000   00000000     000     000         0000000   000  000   000     000

    setPoint: (index, dot, itemPos) ->

        points = @points()
        point  = points[index]

        switch dot
            when 'point'
                switch point[0]
                    when 'S', 'Q', 'C', 'M', 'L'
                        point[point.length-2] = itemPos.x
                        point[point.length-1] = itemPos.y
                    else
                        if @item.type == 'line'
                            point[0] = itemPos.x
                            point[1] = itemPos.y
                            @item.plot points
                        else
                            point[0] = itemPos.x
                            point[1] = itemPos.y

            when 'ctrl1', 'ctrlq', 'ctrls'
                point[1] = itemPos.x
                point[2] = itemPos.y

            when 'ctrl2'
                point[3] = itemPos.x
                point[4] = itemPos.y

            when 'ctrlr'
                prevIndex = index-1
                prevIndex = @numPoints()-1 if prevIndex == 0
                prevp = @posAt prevIndex
                refl = prevp.minus prevp.to itemPos
                prevCtrl = switch @pointAt(prevIndex)[0]
                    when 'C' then 'ctrl2'
                    when 'S' then 'ctrls'
                    when 'Q' then 'ctrlq'
                if prevCtrl
                    @setPoint prevIndex, prevCtrl, refl
                return

        @updateCtrlLines index, point

        if dot == 'point'
            post.emit 'object', 'setPoint', object:@, index:index
            
            if @item.type in ['rect', 'circle', 'ellipse', 'text']
                @trans.setItemPoints @item, points
        
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
                @straightenPoint index, 'prev'
                @straightenPoint previ, 'next'
            when 'ctrlr' then
            when 'ctrls'
                @straightenPoint index, 'prev'
            when 'ctrl1'
                @straightenPoint previ, 'next'
            when 'ctrl2'
                @straightenPoint index, 'prev'
            when 'point'
                @straightenPoint index, 'none'

    straightenPoint: (index, fixed) ->
        
        mover = new Mover @
        
        info = mover.infoAt index
        
        nexti = index+1
        nexti = 0 if nexti == @numPoints()
        
        switch fixed
            
            when 'next'
                
                prevPos = info.thisPos.minus info.toNext.normal().times info.toPrev.length()
                @setPoint index, info.prevDot, prevPos
            
            when 'prev'
                
                nextPos = info.thisPos.minus info.toPrev.normal().times info.toNext.length()
                @setPoint nexti, info.nextDot, nextPos
                
            when 'none'
                
                if Math.abs(info.angle) > 179.9999 or Math.abs(info.angle) < 0.0001
                    return

                if info.angle > 0
                    prevAngle =  90 - info.angle / 2
                    nextAngle = -90 + info.angle / 2
                else
                    prevAngle = -90 - info.angle / 2
                    nextAngle =  90 + info.angle / 2
                
                prevPos = info.thisPos.plus info.toPrev.rotate(prevAngle)
                nextPos = info.thisPos.plus info.toNext.rotate(nextAngle)

                @setPoint index, info.prevDot, prevPos
                @setPoint nexti, info.nextDot, nextPos
                
        @edit.update()
        @plot()
        
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
            @setPoint index, dot.dot, itemPos

        @plot()

    # 0000000    000  000   000  000  0000000    00000000
    # 000   000  000  000   000  000  000   000  000
    # 000   000  000   000 000   000  000   000  0000000
    # 000   000  000     000     000  000   000  000
    # 0000000    000      0      000  0000000    00000000

    divide: (dots) ->

        newDots = []

        points = @points()

        indexDots = @indexDots dots

        for idots in indexDots

            index = idots.index
            point = points[index]

            continue if index == 0

            thisp = @posAt index
            prevp = @posAt index-1

            switch point[0]

                when 'C'

                    ctrl1 = @posAt index, 'ctrl1'
                    ctrl2 = @posAt index, 'ctrl2'

                    scale = 3/4
                    mid1 = prevp.plus (prevp.to ctrl1).scale scale
                    mid2 = thisp.plus (thisp.to ctrl2).scale scale
                    mid3 = mid1.mid mid2

                    ctrl11 = prevp.plus (prevp.to mid1).scale scale
                    ctrl12 = mid3.plus (mid3.to mid1).scale   scale

                    ctrl21 = mid3.plus (mid3.to mid2).scale   scale
                    ctrl22 = thisp.plus (thisp.to mid2).scale scale

                    newPoint = ['C', ctrl21.x, ctrl21.y, ctrl22.x, ctrl22.y, point[5], point[6]]

                    point[1] = ctrl11.x
                    point[2] = ctrl11.y
                    point[3] = ctrl12.x
                    point[4] = ctrl12.y
                    point[5] = mid3.x
                    point[6] = mid3.y

                when 'Q', 'S'

                    ctrl  = pos point[1], point[2]
                    ctrl1 = prevp.mid ctrl
                    ctrl2 = thisp.mid ctrl
                    mid = ctrl1.mid ctrl2

                    newPoint = [point[0], ctrl2.x, ctrl2.y, point[3], point[4]]

                    point[1] = ctrl1.x
                    point[2] = ctrl1.y
                    point[3] = mid.x
                    point[4] = mid.y

                when 'M', 'L'

                    newPoint = [point[0], point[1], point[2]]

                    mid = prevp.mid thisp
                    point[1] = mid.x
                    point[2] = mid.y
                    
                else
                    
                    newPoint = [point[0], point[1]]
                    mid = prevp.mid thisp
                    point[0] = mid.x
                    point[1] = mid.y

            @initCtrlDots   index, point
            @updateCtrlDots index, point

            newDots = newDots.concat _.values @ctrls[index].dots

            points.splice index+1, 0, newPoint
            @ctrls.splice index+1, 0, new Ctrl @

            @initCtrlDots   index+1, newPoint
            @updateCtrlDots index+1, newPoint

            newDots = newDots.concat _.values @ctrls[index+1].dots

        @plot()
        newDots

    #  0000000   0000000   000   000  000   000  00000000  00000000   000000000
    # 000       000   000  0000  000  000   000  000       000   000     000
    # 000       000   000  000 0 000   000 000   0000000   0000000       000
    # 000       000   000  000  0000     000     000       000   000     000
    #  0000000   0000000   000   000      0      00000000  000   000     000

    convertDots: (dots, type) ->
        
        if type == 'D' then return @divide dots

        newDots = []

        points = @points()

        indexDots = @indexDots dots

        for idots in indexDots

            index = idots.index
            point = points[index]

            continue if index == 0

            thisp = @posAt index
            prevp = @posAt index-1

            switch type

                when 'C'

                    switch point[0]
                        when 'C'
                            newDots = newDots.concat _.values @ctrls[index].dots
                            continue
                        when 'Q'
                            ctrl = pos point[1], point[2]
                            mid1 = prevp.plus (prevp.to ctrl).times 2/3
                            mid2 = thisp.plus (thisp.to ctrl).times 2/3
                            point.splice 1, 2, mid1.x, mid1.y, mid2.x, mid2.y
                        when 'S'
                            ctrls = @posAt index, 'ctrls'
                            ctrlr = @posAt index, 'ctrlr'
                            point.splice 1, 2, ctrlr.x, ctrlr.y, ctrls.x, ctrls.y
                        when 'M', 'L'
                            mid1 = prevp.plus (prevp.to thisp).times 1/3
                            mid2 = prevp.plus (prevp.to thisp).times 2/3
                            point.splice 1, 0, mid1.x, mid1.y, mid2.x, mid2.y

                    point[0] = 'C'

                when 'Q'

                    switch point[0]
                        when 'Q'
                            newDots = newDots.concat _.values @ctrls[index].dots
                            continue
                        when 'C'
                            ext1 = prevp.plus (prevp.to @posAt index, 'ctrl1').times 3/2
                            ext2 = thisp.plus (thisp.to @posAt index, 'ctrl2').times 3/2
                            midp = ext1.mid ext2
                            point.splice 1, 4, midp.x, midp.y
                        when 'M', 'L'
                            midp = prevp.mid thisp
                            point.splice 1, 0, midp.x, midp.y

                    point[0] = 'Q'

                when 'S'

                    switch point[0]
                        when 'S'
                            newDots = newDots.concat _.values @ctrls[index].dots
                            continue
                        when 'C'
                            point.splice 1, 2
                        when 'M', 'L'
                            midp = prevp.mid thisp
                            point.splice 1, 0, midp.x, midp.y

                    point[0] = 'S'
                    
                when 'P'
                    
                    point[0] = point[point.length-2]
                    point[1] = point[point.length-1]
                    point.splice 2, point.length-2

            @initCtrlDots   index, point
            @updateCtrlDots index, point

            newDots = newDots.concat _.values @ctrls[index].dots

        @plot()
        newDots

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
            @plot()
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
        @plot()
        @updateCtrlDots index+1, @pointAt index+1 if index < @numPoints()-1

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveCtrlsBy: (delta) ->

        for ctrl in @ctrls
            ctrl.moveBy delta.times 1.0/@kali.stage.zoom

    plot: (points) -> 
    
        points ?= @trans.itemPoints @item
        @trans.setItemPoints @item, points

    dots: ->
        dots = []
        for ctrl in @ctrls
            dots = dots.concat _.values ctrl.dots
        dots

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

    numPoints: -> @points()?.length ? 0
    pointAt: (index) -> @points()[@index index]
    ctrlAt: (index) -> 
        if index in ['fill', 'stroke']
            return gradi?[index]
        @ctrls[@index index]
        
    points: -> @trans.itemPoints @item

    index: (index) -> (@numPoints() + index) % @numPoints()

    posAt: (index, dot='point') ->

        index = @index index

        p = @pointAt index

        switch dot
            when 'point'
                switch p[0]
                    when 'C'               then pos p[5], p[6]
                    when 'S', 'Q'          then pos p[3], p[4]
                    when 'M', 'L'          then pos p[1], p[2]
                    else                        pos p[0], p[1]
            when 'ctrl1', 'ctrls', 'ctrlq' then pos p[1], p[2]
            when 'ctrl2'                   then pos p[3], p[4]
            when 'ctrlb'
                point = @pointAt index
                switch point[0]
                    when 'C' then @posAt index, 'ctrl2'
                    when 'S' then @posAt index, 'ctrls'
                    when 'Q' then @posAt index, 'ctrlq'
                    else          @posAt index
            when 'ctrlr'
                index = @numPoints() if index == 1
                prevp = @posAt index-1
                ctrlb = @posAt index-1, 'ctrlb'
                prevp.minus prevp.to ctrlb

            else
                log "Object.posAt -- unhandled dot? #{dot}"
                pos p[1], p[2]

    pointCode: (index) ->
        if @isPoly()
            'P'
        else
            @pointAt(index)[0]

    isPoly: -> @item.type in ['polygon', 'polyline', 'line', 'circle', 'ellipse', 'rect', 'text']
    isPath: -> not @isPoly()

module.exports = Object

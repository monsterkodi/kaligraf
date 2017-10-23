###
00     00   0000000   000   000  00000000  00000000 
000   000  000   000  000   000  000       000   000
000000000  000   000   000 000   0000000   0000000  
000 0 000  000   000     000     000       000   000
000   000   0000000       0      00000000  000   000
###

{ empty, valid, pos, log, _ } = require 'kxk'

{ linesIntersect } = require '../utils'

class Mover

    constructor: (@kali, @item, @cfg) ->

        @cfg ?= {}

        @trans = @kali.trans
        
        if @cfg?.indexDots?
            @moveIndexDots()
        
    # 00     00   0000000   000   000  00000000  0000000     0000000   000000000   0000000  
    # 000   000  000   000  000   000  000       000   000  000   000     000     000       
    # 000000000  000   000   000 000   0000000   000   000  000   000     000     0000000   
    # 000 0 000  000   000     000     000       000   000  000   000     000          000  
    # 000   000   0000000       0      00000000  0000000     0000000      000     0000000   
    
    moveIndexDots: ->
        
        indexDots = @cfg.indexDots

        follow = []
        
        if not @cfg.event? or not @cfg.event.ctrlKey

            for idots in indexDots

                if idots.dots.length == 1 and @cfg.event? and not @cfg.event.ctrlKey
                    
                    if idots.dots[0] in ['ctrl1', 'ctrlq']          
                        
                        previ = idots.index-1
                        if previ == 0 then previ = @numPoints()-1
                        follow.push fixed: 'next', info: @infoAt previ
                        
                    if idots.dots[0] in ['ctrl2', 'ctrlq', 'ctrls'] 
                        
                        follow.push fixed: 'prev', info: @infoAt idots.index
                    
                add = (type, index) =>
                    idts = indexDots.find (i) -> i.index == index
                    if not idts?
                        idts = index:index, dots:[]
                        indexDots.push idts
                    if type not in idts.dots
                        idts.dots.push type

                if valid idots.dots.filter((dot) -> dot == 'point')

                    switch @pointCode idots.index

                        when 'C' then add 'ctrl2', idots.index
                        when 'S' then add 'ctrls', idots.index
                        when 'Q' then add 'ctrlq', idots.index

                    nexti = idots.index+1
                    if nexti >= @numPoints()
                        if @isClosed()
                            nexti = 1 
                        else
                            continue

                    switch @pointCode nexti

                        when 'C' then add 'ctrl1', nexti
                        when 'Q' then add 'ctrlq', nexti

        for idots in indexDots
            
            if 'ctrlr' in idots.dots
                previ = idots.index-1
                previ = @numPoints()-1 if previ == 0
                if idts = indexDots.find((i) -> i.index == previ)
                    ctrls = ['point', 'ctrls', 'ctrlq', 'ctrl2']
                    if valid _.intersection(ctrls, idts.dots)
                        idots.dots = idots.dots.filter (d) -> d != 'ctrlr'
                        idts.dots.push('point') if 'point' not in idts.dots

        itemDelta = @trans.fullInverse(@item, @cfg.delta).minus @trans.fullInverse(@item, pos(0,0))
        
        indexDots = indexDots.filter (idts) -> idts.dots.length

        for idots in indexDots
            
            for dot in idots.dots
                oldPos = @posAt idots.index, dot
                newPos = oldPos.plus itemDelta
                @movePoint idots.index, newPos, dot

        for f in follow 
            @setAngle f.fixed, f.info
        
        @trans.setItemPoints @item, @points()

    # 00     00   0000000   000   000  00000000  00000000    0000000   000  000   000  000000000
    # 000   000  000   000  000   000  000       000   000  000   000  000  0000  000     000
    # 000000000  000   000   000 000   0000000   00000000   000   000  000  000 0 000     000
    # 000 0 000  000   000     000     000       000        000   000  000  000  0000     000
    # 000   000   0000000       0      00000000  000         0000000   000  000   000     000

    movePoint: (index, itemPos, dots=['point']) ->

        points = @points()
        point  = points[index]

        if _.isString dots then dots = [dots]
        
        for dot in dots

            switch dot
                when 'point'
                    switch point[0]
                        when 'S', 'Q', 'C', 'M', 'L'
                            point[point.length-2] = itemPos.x
                            point[point.length-1] = itemPos.y
                        else
                            point[0] = itemPos.x
                            point[1] = itemPos.y
                            if @item.type == 'line'
                                @item.plot points

                when 'ctrl1', 'ctrlq', 'ctrls'
                    point[1] = itemPos.x
                    point[2] = itemPos.y

                when 'ctrl2'
                    point[3] = itemPos.x
                    point[4] = itemPos.y

                when 'ctrlr'
                    previ = index-1
                    previ = @numPoints()-1 if previ == 0
                    prevCtrl = switch @pointAt(previ)[0]
                        when 'C' then 'ctrl2'
                        when 'S' then 'ctrls'
                        when 'Q' then 'ctrlq'
                    if prevCtrl
                        prevp = @posAt previ 
                        refl  = prevp.minus prevp.to itemPos
                        @movePoint previ, refl, prevCtrl
            
    #  0000000   000   000   0000000   000      00000000  
    # 000   000  0000  000  000        000      000       
    # 000000000  000 0 000  000  0000  000      0000000   
    # 000   000  000  0000  000   000  000      000       
    # 000   000  000   000   0000000   0000000  00000000  
    
    setAngle: (fixed, oldInfo) ->
        
        newInfo = @infoAt oldInfo.index

        switch fixed
            when 'prev'
                nexti = oldInfo.index+1
                if nexti >= @numPoints()
                    if @isClosed() then nexti = 1 
                    else return
                newPos = newInfo.thisPos.plus newInfo.toPrev.rotate(-oldInfo.angle).normal().times oldInfo.toNext.length()
                @setDotPos oldInfo.nextDot, nexti, newPos
            when 'next'
                if oldInfo.index >= @numPoints()-1 and not @isClosed()
                    return
                newPos = newInfo.thisPos.plus newInfo.toNext.rotate(oldInfo.angle).normal().times oldInfo.toPrev.length()
                @setDotPos oldInfo.prevDot, oldInfo.index, newPos
                
    # 000  000   000  00000000   0000000   
    # 000  0000  000  000       000   000  
    # 000  000 0 000  000000    000   000  
    # 000  000  0000  000       000   000  
    # 000  000   000  000        0000000   
    
    infoAt: (index) ->
        
        nexti = index+1
        nexti = 1 if nexti == @numPoints()
        
        info = {}
        
        info.index = index
        info.point = @pointAt index
        
        info.prevDot = switch info.point[0]
            when 'C' then 'ctrl2'
            when 'S' then 'ctrls'
            when 'Q' then 'ctrlq'
            
        info.nextDot = switch @pointAt(nexti)[0]
            when 'C' then 'ctrl1'
            when 'S' then 'ctrlr'
            when 'Q' then 'ctrlq'
        
        info.thisPos = @posAt index
        info.prevPos = @posAt index, info.prevDot
        info.nextPos = @posAt nexti, info.nextDot

        info.toNext = info.thisPos.to info.nextPos
        info.toPrev = info.thisPos.to info.prevPos
        
        info.angle  = info.toPrev.rotation info.toNext
        
        info
            
    # 00000000    0000000   000  000   000  000000000   0000000  
    # 000   000  000   000  000  0000  000     000     000       
    # 00000000   000   000  000  000 0 000     000     0000000   
    # 000        000   000  000  000  0000     000          000  
    # 000         0000000   000  000   000     000     0000000   
    
    isPoly: -> @item.type in ['polygon', 'polyline', 'line', 'circle', 'ellipse', 'rect', 'text', 'image']
    isPath: -> @item.type in ['polygon', 'polyline', 'line', 'path']
    numPoints: -> @points()?.length ? 0
    pointAt: (index) -> @points()[@index index]        
    points: -> 
        switch @item.type
            when 'circle', 'ellipse', 'rect', 'text', 'image'
                if empty @fakePoints
                    @fakePoints = @trans.itemPoints @item
                return @fakePoints
        @trans.itemPoints @item

    pointCode: (index) -> if @isPoly() then 'P' else @pointAt(index)[0]
    index: (index) -> (@numPoints() + index) % @numPoints()

    isClosed: -> @posAt(0).to(@posAt @numPoints()-1).length() < 0.0001
    
    # 00000000    0000000    0000000   0000000   000000000  
    # 000   000  000   000  000       000   000     000     
    # 00000000   000   000  0000000   000000000     000     
    # 000        000   000       000  000   000     000     
    # 000         0000000   0000000   000   000     000     
    
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
                log "Mover.posAt -- unhandled dot? #{dot}"
                pos p[1], p[2]

    setDotPos: (dot, index, itemPos) ->
        
        point = @points()[index]
        
        switch dot

            when 'ctrl1', 'ctrlq', 'ctrls'
                point[1] = itemPos.x
                point[2] = itemPos.y

            when 'ctrl2'
                point[3] = itemPos.x
                point[4] = itemPos.y
                
            when 'point'
                switch point[0]
                    when 'S', 'Q', 'C', 'M', 'L'
                        point[point.length-2] = itemPos.x
                        point[point.length-1] = itemPos.y
                    else
                        point[0] = itemPos.x
                        point[1] = itemPos.y

    #  0000000   0000000    0000000    00000000  000   000  00000000  000   000  
    # 000   000  000   000  000   000  000       000   000  000       0000  000  
    # 000   000  000   000  000   000  0000000    000 000   0000000   000 0 000  
    # 000   000  000   000  000   000  000          000     000       000  0000  
    #  0000000   0000000    0000000    00000000      0      00000000  000   000  
    
    oddEvenTest: (stagePos) ->
        
        positions = @approxPositions 3
        numPoints = positions.length
        return false if not numPoints
        outsidePos = pos stagePos.x+999999, stagePos.y
        count = 0
        for index in [0...numPoints-1]
            
            # l = @kali.stage.svg.line()
            # l.style 'stroke-width': 2, 'stroke': 'white'
            # l.plot positions[index].x, positions[index].y, positions[index+1].x, positions[index+1].y
            
            if linesIntersect positions[index], positions[index+1], stagePos, outsidePos
                count += 1
        return (count % 2) != 0
        
    approxPositions: (subdivisions) ->
        log @item.type
        points    = @points()
        numPoints = points.length
        positions = []

        for index in [0...numPoints]
            point = points[index]
            switch point[0]
                when 'S', 'Q', 'C'
                    if index > 0
                        for subdiv in [1..subdivisions]
                            positions.push @trans.fullTransform @item, @deCasteljauPos index, point, subdiv/(subdivisions+1)
                    positions.push @trans.fullTransform @item, @posAt index
                else
                    positions.push @trans.fullTransform @item, @posAt index
        positions

    deCasteljauPos: (index, point, factor) ->
        
        thisp = @posAt index
        prevp = @posAt index-1
        
        switch point[0]
            when 'C'
                ctrl1 = @posAt index, 'ctrl1'
                ctrl2 = @posAt index, 'ctrl2'
            when 'Q'
                ctrl1 = @posAt index, 'ctrlq'
                ctrl2 = ctrl1
            when 'S'
                ctrl1 = @posAt index, 'ctrlr'
                ctrl2 = @posAt index, 'ctrls'

        p1 = prevp.interpolate ctrl1, factor
        p2 = ctrl1.interpolate ctrl2, factor
        p3 = ctrl2.interpolate thisp, factor
        
        p4 = p1.interpolate p2, factor
        p5 = p2.interpolate p3, factor
        p6 = p4.interpolate p5, factor
        
module.exports = Mover

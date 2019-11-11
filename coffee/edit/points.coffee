###
00000000    0000000   000  000   000  000000000   0000000  
000   000  000   000  000  0000  000     000     000       
00000000   000   000  000  000 0 000     000     0000000   
000        000   000  000  000  0000     000          000  
000         0000000   000  000   000     000     0000000   
###

{ post, valid, empty, first, kpos, _ } = require 'kxk'

{ linesIntersect, itemMatrix } = require '../utils'

Convert = require './convert'

class Points extends Convert

    constructor: (kali, item) ->
        super()
        @kali  = kali
        @item  = item
        @trans = @kali.trans
        
    # 00     00   0000000   000   000  00000000     0000000     0000000   000000000   0000000  
    # 000   000  000   000  000   000  000          000   000  000   000     000     000       
    # 000000000  000   000   000 000   0000000      000   000  000   000     000     0000000   
    # 000 0 000  000   000     000     000          000   000  000   000     000          000  
    # 000   000   0000000       0      00000000     0000000     0000000      000     0000000   
    
    moveIndexDots: (cfg) ->

        indexDots = cfg.indexDots

        coincident = @coincident()

        follow = []

        add = (type, idx) =>
            idts = indexDots.find (i) -> i.index == idx
            if not idts?
                idts = index:idx, dots:[]
                indexDots.push idts
            if type not in idts.dots
                idts.dots.push type
        
        if not cfg.event? or not cfg.event.altKey
            
            for idots in indexDots
                index = idots.index
                if valid idots.dots.filter((dot) -> dot == 'point')
                    li = coincident.indices.indexOf index
                    if li > -1
                        for idx in coincident.lists[li]
                            add 'point', idx

        if not cfg.event? or not cfg.event.ctrlKey
                                            
            for idots in indexDots

                index = idots.index
                
                if idots.dots.length == 1 and cfg.event? and not cfg.event.ctrlKey
                    
                    if idots.dots[0] in ['ctrl1', 'ctrlq']          
                        
                        previ = index-1
                        if previ == 0 then previ = @numPoints()-1
                        follow.push fixed: 'next', info: @infoAt previ
                        
                    if idots.dots[0] in ['ctrl2', 'ctrlq', 'ctrls'] 
                        
                        follow.push fixed: 'prev', info: @infoAt index
                    
                if valid idots.dots.filter((dot) -> dot == 'point')
                    
                    switch @pointCode index
                        when 'C' then add 'ctrl2', index
                        when 'S' then add 'ctrls', index
                        when 'Q' then add 'ctrlq', index

                    nexti = index+1
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

        itemDelta = @trans.fullInverse(@item, cfg.delta).minus @trans.fullInverse(@item, pos(0,0))
        
        indexDots = indexDots.filter (idts) -> idts.dots.length

        for idots in indexDots
            
            for dot in idots.dots
                oldPos = @posAt idots.index, dot
                newPos = oldPos.plus itemDelta
                @movePoint idots.index, newPos, dot

        for f in follow 
            @setAngle f.fixed, f.info
        
        @applyPoints @points()

    #  0000000   0000000   000  000   000   0000000  000  0000000    00000000  000   000  000000000  
    # 000       000   000  000  0000  000  000       000  000   000  000       0000  000     000     
    # 000       000   000  000  000 0 000  000       000  000   000  0000000   000 0 000     000     
    # 000       000   000  000  000  0000  000       000  000   000  000       000  0000     000     
    #  0000000   0000000   000  000   000   0000000  000  0000000    00000000  000   000     000     
    
    coincident: ->
        
        indexPositions = @indexPositions()
        coincident = indices:[], lists:[]
        
        while indexPositions.length > 1
            [i1, p1] = indexPositions.shift()

            numPos = indexPositions.length-1
            for index in [numPos..0]
                [i2, p2] = indexPositions[index]
                
                if p1.isClose p2, 1/@kali.stage.zoom
                    
                    li1 = coincident.indices.indexOf i1
                    if li1 < 0
                        coincident.indices.push i1
                        coincident.lists.push [i2]
                    else
                        coincident.lists[li1].push i2
                        
                    coincident.indices.push i2
                    coincident.lists.push []
                        
                    indexPositions.splice index, 1

        for li1,i1 of coincident.indices
            for i2 in coincident.lists[li1]
                li2 = coincident.indices.indexOf i2
                l = _.clone coincident.lists[li1]
                _.pull l, i2
                l.push i1
                coincident.lists[li2] = l
                
        coincident
        
    # 00     00   0000000   000   000  00000000     00000000    0000000   000  000   000  000000000
    # 000   000  000   000  000   000  000          000   000  000   000  000  0000  000     000
    # 000000000  000   000   000 000   0000000      00000000   000   000  000  000 0 000     000
    # 000 0 000  000   000     000     000          000        000   000  000  000  0000     000
    # 000   000   0000000       0      00000000     000         0000000   000  000   000     000

    movePoint: (index, itemPos, dots=['point']) =>
        
        if _.isString dots then dots = [dots]
        
        for dot in dots

            @setDotPos index, dot, itemPos, @movePoint

    #  0000000  00000000  000000000     00000000    0000000   000  000   000  000000000  
    # 000       000          000        000   000  000   000  000  0000  000     000     
    # 0000000   0000000      000        00000000   000   000  000  000 0 000     000     
    #      000  000          000        000        000   000  000  000  0000     000     
    # 0000000   00000000     000        000         0000000   000  000   000     000     
    
    setPoint: (index, itemPos, dot='point') =>
        
        points = @points()

        @setDotPos index, dot, itemPos, @setPoint

        if dot == 'point'
            
            post.emit 'points', 'setPoint', item:@item, index:index
            
            if @isFake() then @applyPoints points

    setDotPos: (index, dot, itemPos, setRefl) ->
        
        points    = @points()
        numPoints = points.length
        point     = points[index]
        
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
                previ = numPoints-1 if previ == 0
                prevDot = switch points[previ][0]
                    when 'C' then 'ctrl2'
                    when 'S' then 'ctrls'
                    when 'Q' then 'ctrlq'
                if prevDot and setRefl?
                    prevp = @posAt previ
                    refl = prevp.minus prevp.to itemPos
                    setRefl previ, refl, prevDot

    #  0000000  000000000  00000000    0000000   000   0000000   000   000  000000000  00000000  000   000  
    # 000          000     000   000  000   000  000  000        000   000     000     000       0000  000  
    # 0000000      000     0000000    000000000  000  000  0000  000000000     000     0000000   000 0 000  
    #      000     000     000   000  000   000  000  000   000  000   000     000     000       000  0000  
    # 0000000      000     000   000  000   000  000   0000000   000   000     000     00000000  000   000  
    
    straighten: (index, fixed) ->
        
        if not @isClosed()
            return if index >= @numPoints()-1
            return if index <= 1
        
        info  = @infoAt index
        nexti = index+1
        nexti = 1 if nexti >= @numPoints()
        
        switch fixed
            
            when 'next'
                prevPos = info.thisPos.minus info.toNext.normal().times info.toPrev.length()
                @setPoint index, prevPos, info.prevDot
            
            when 'prev'
                nextPos = info.thisPos.minus info.toPrev.normal().times info.toNext.length()
                @setPoint nexti, nextPos, info.nextDot
                
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

                @setPoint index, prevPos, info.prevDot
                @setPoint nexti, nextPos, info.nextDot
                
        @applyPoints()
                    
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
                @setDotPos nexti, oldInfo.nextDot, newPos
                
            when 'next'
                if oldInfo.index >= @numPoints()-1 and not @isClosed()
                    return
                newPos = newInfo.thisPos.plus newInfo.toNext.rotate(oldInfo.angle).normal().times oldInfo.toPrev.length()
                @setDotPos oldInfo.index, oldInfo.prevDot, newPos
                
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
    
    @isFakeItem: (item) -> item.type in ['circle', 'ellipse', 'rect', 'text', 'image', 'use']
    isFake: -> Points.isFakeItem @item
    isPoly: -> @item.type in ['polygon', 'polyline', 'line', 'circle', 'ellipse', 'rect', 'text', 'image']
    isPath: -> @item.type == 'path'
    numPoints: -> @points()?.length ? 0
    pointAt: (index) -> @points()[@index index]        
    index: (index) -> (@numPoints() + index) % @numPoints()
    pointCode: (index) -> 
        if 'snaprect' == @item.data('type') then 'B'
        else if @isPoly() then 'P' 
        else @pointAt(index)[0]

    isClosed: -> @posAt(0).to(@posAt @numPoints()-1).length() < 0.0001

    @itemPoints: (item) ->
        
        if @isFakeItem item
            
            box = item.bbox()
            return [
                [box.x,  box.y,  'top left' ]
                [box.cx, box.y,  'top'      ]
                [box.x2, box.y,  'top right']
                [box.x2, box.cy, 'right'    ]
                [box.x2, box.y2, 'bot right']
                [box.cx, box.y2, 'bot'      ]
                [box.x,  box.y2, 'bot left' ]
                [box.x,  box.cy, 'left'     ]
                [box.cx, box.cy, 'center'   ]
            ]
            
        item.array?().valueOf()

    @itemPos: (item, index) ->
        
        points = @itemPoints item
        point = points[index]
        itemPos = switch point[0]
            when 'C'      then kpos point[5], point[6]
            when 'S', 'Q' then kpos point[3], point[4]
            when 'M', 'L' then kpos point[1], point[2]
            else               kpos point[0], point[1]
            
        kpos new SVG.Point(itemPos).transform itemMatrix item
        
    points: -> 
        
        if @isFake()
            if empty @fakePoints
                @updateFakePoints()
            return @fakePoints

        if not @item.array? then log 'DAFUK!', @item
        
        @item.array?().valueOf()
    
    updateFakePoints: -> @fakePoints = Points.itemPoints @item
        
    applyPoints: (points=@points()) -> 
        
        if @isFake()
            
            # log 'points.applyPoints', points
            
            center = kpos points[8][0], points[8][1]
            center = @trans.transform @item, center
            @trans.setCenter @item, center
            switch @item.type
                when 'circle'
                    top   = kpos points[1][0], points[1][1]
                    bot   = kpos points[5][0], points[5][1]
                    left  = kpos points[7][0], points[7][1]
                    right = kpos points[3][0], points[3][1]
                    radius = (top.to(bot).length() + left.to(right).length())/4
                    @item.attr r: radius
            @updateFakePoints()
        else
            @item.plot points
        
    # 00000000    0000000    0000000       0000000   000000000  
    # 000   000  000   000  000           000   000     000     
    # 00000000   000   000  0000000       000000000     000     
    # 000        000   000       000      000   000     000     
    # 000         0000000   0000000       000   000     000     
    
    posAt: (index, dot='point') ->

        index = @index   index
        point = @pointAt index

        switch dot
            when 'point' then @posForPoint point
            when 'ctrl1', 'ctrls', 'ctrlq' then kpos point[1], point[2]
            when 'ctrl2'                   then kpos point[3], point[4]
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
                log "Points.posAt -- unhandled dot? #{dot}"
                kpos point[1], point[2]

    posForPoint: (point) ->
                
        switch point[0]
            when 'C'               then kpos point[5], point[6]
            when 'S', 'Q'          then kpos point[3], point[4]
            when 'M', 'L'          then kpos point[1], point[2]
            else                        kpos point[0], point[1]

    indexPositions: ->
        
        positions = []
        for index in [0...@numPoints()]
            positions.push [index, @posAt index]
        positions
            
    #  0000000   0000000    0000000         00000000  000   000  00000000  000   000  
    # 000   000  000   000  000   000       000       000   000  000       0000  000  
    # 000   000  000   000  000   000       0000000    000 000   0000000   000 0 000  
    # 000   000  000   000  000   000       000          000     000       000  0000  
    #  0000000   0000000    0000000         00000000      0      00000000  000   000  
    
    oddEvenTest: (stagePos) ->
        
        positions = @approxPositions 3
        numPoints = positions.length
        return false if not numPoints
        outsidePos = kpos stagePos.x+999999,stagePos.y
        count = 0
                
        for index in [0...numPoints-1]
            
            if linesIntersect positions[index], positions[index+1], stagePos, outsidePos
                count += 1
                
        return (count % 2) != 0
        
    approxPositions: (subdivisions) ->

        points = @points()
        
        indexPoints = []
        for index,point of points
            indexPoints.push [index, point]

        if @isFake()
            indexPoints.pop()
        
        indexPoints.push first indexPoints
            
        numPoints = indexPoints.length
        positions = []
        
        addPos = (p) => positions.push @trans.fullTransform @item, p
        
        for [index, point] in indexPoints
            switch point[0]
                when 'S', 'Q', 'C'
                    if index > 0
                        for subdiv in [1..subdivisions]
                            addPos @deCasteljauPos index, point, subdiv/(subdivisions+1)
                    addPos @posForPoint point
                else
                    addPos @posForPoint point
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
                                    
module.exports = Points

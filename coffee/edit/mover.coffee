
# 00     00   0000000   000   000  00000000  00000000 
# 000   000  000   000  000   000  000       000   000
# 000000000  000   000   000 000   0000000   0000000  
# 000 0 000  000   000     000     000       000   000
# 000   000   0000000       0      00000000  000   000

{ empty, valid, pos, log, _ } = require 'kxk'

class Mover

    constructor: (@kali, @item, cfg) ->

        @trans = @kali.trans
        
        indexDots = cfg.indexDots

        if not cfg.event? or not cfg.event.ctrlKey

            for idots in indexDots

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

                    nextIndex = idots.index+1
                    nextIndex = 1 if nextIndex >= @numPoints()

                    switch @pointCode nextIndex

                        when 'C' then add 'ctrl1', nextIndex
                        when 'Q' then add 'ctrlq', nextIndex

        for idots in indexDots
            
            if 'ctrlr' in idots.dots
                prevIndex = idots.index-1
                prevIndex = @numPoints()-1 if prevIndex == 0
                if idts = indexDots.find((i) -> i.index == prevIndex)
                    ctrls = ['point', 'ctrls', 'ctrlq', 'ctrl2']
                    if valid _.intersection(ctrls, idts.dots)
                        idots.dots = idots.dots.filter (d) -> d != 'ctrlr'
                        idts.dots.push('point') if 'point' not in idts.dots

        itemDelta = @trans.inverse(@item, cfg.delta).minus @trans.inverse(@item, pos(0,0))

        indexDots = indexDots.filter (idts) -> idts.dots.length

        for idots in indexDots

            for dot in idots.dots
                oldPos = @posAt idots.index, dot
                newPos = oldPos.plus itemDelta
                @movePoint idots.index, newPos, dot
                
        @item.plot @points()

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
                            if @item.type == 'line'
                                point[0] = itemPos.x
                                point[1] = itemPos.y
                                @item.plot points
                            else
                                point[0] = itemPos.x
                                point[1] = itemPos.y

                    # if @isPath() and not @edit.passive and index == @numPoints()-1

                        # log 'fix closed!'
                        # if false

                            # firstPoint = @pointAt 0
                            # firstPoint[1] = itemPos.x
                            # firstPoint[2] = itemPos.y

                            # @updateCtrlDots 0, firstPoint
                            # @updateCtrlDots 1, @pointAt 1 if points.length>1

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
                        @movePoint prevIndex, refl, prevCtrl

    isPoly: -> @item.type in ['polygon', 'polyline', 'line']
    numPoints: -> @points()?.length ? 0
    pointAt: (index) -> @points()[@index index]        
    points: -> @item.type != 'text' and @item.array?().valueOf()
    pointCode: (index) -> if @isPoly() then 'P' else @pointAt(index)[0]
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
                log "Mover.posAt -- unhandled dot? #{dot}"
                pos p[1], p[2]

module.exports = Mover

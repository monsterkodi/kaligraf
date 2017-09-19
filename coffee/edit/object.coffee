
#  0000000   0000000          000  00000000   0000000  000000000
# 000   000  000   000        000  000       000          000
# 000   000  0000000          000  0000000   000          000
# 000   000  000   000  000   000  000       000          000
#  0000000   0000000     0000000   00000000   0000000     000

{ pos, empty, log, _ } = require 'kxk'

Ctrl = require './ctrl'

class Object

    constructor: (@edit, item) ->

        @svg   = @edit.svg
        @kali  = @edit.kali
        @trans = @kali.trans
        @stage = @kali.stage

        @ctrls = []

        if item? then @setItem item

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        for ctrl in @ctrls
            ctrl.del()

        @ctrls = []

    #  0000000  00000000  000000000     000  000000000  00000000  00     00
    # 000       000          000        000     000     000       000   000
    # 0000000   0000000      000        000     000     0000000   000000000
    #      000  000          000        000     000     000       000 0 000
    # 0000000   00000000     000        000     000     00000000  000   000

    setItem: (item) ->

        @del()

        @item = item
        
        points = @points()

        for i in [0...points.length]
            
            @initCtrlDots   i, points[i]
            @updateCtrlDots i, points[i]

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

    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    updateCtrlDots: (index, point) ->
        
        # log "updateCtrlDots #{index}"
        @ctrls[index].updateDots point
                
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

        indexDots = @indexDots dots
        
        if not event? or not event.ctrlKey
            # log 'before:', indexDots.map (id) -> "index: #{id.index}" + (id.dots.map (d) -> d.dot).join(',')
            for idots in indexDots
                
                add = (type, index) => 

                    dot  = @ctrls[index].dots[type]
                    idts = indexDots.find (i) -> i.index == index 
                    if not idts?
                        idts = index:index, dots:[]
                        indexDots.push idts

                    if dot not in idts.dots 
                        idts.dots.push dot
                        
                if not empty idots.dots.filter((dot) -> dot.dot == 'point')
                    
                    switch @pointCode idots.index
                        
                        when 'S' then add 'ctrls', idots.index
                        when 'Q' then add 'ctrlq', idots.index
                        when 'C' then add 'ctrl2', idots.index

                    if idots.index < @numPoints()-1
                        nextIndex = idots.index+1
                    else
                        nextIndex = 1

                    switch @pointCode nextIndex
                        when 'Q' then add 'ctrlq', nextIndex
                        when 'C' then add 'ctrl1', nextIndex
                  
            
        for idots in indexDots
            if idots.dots.length > 1
                idots.dots = idots.dots.filter (dot) -> dot.dot != 'ctrlr' 
            
        # log 'after:', indexDots.map (id) -> "index: #{id.index}" + (id.dots.map (d) -> d.dot).join ','
        
        for idots in indexDots
            
            for dot in idots.dots
                oldPos = @dotPos idots.index, dot.dot
                newPos = oldPos.plus delta
                @movePoint idots.index, newPos, dot.dot
            
        @plot()

        
    #  0000000   0000000   000   000  000   000  00000000  00000000   000000000  
    # 000       000   000  0000  000  000   000  000       000   000     000     
    # 000       000   000  000 0 000   000 000   0000000   0000000       000     
    # 000       000   000  000  0000     000     000       000   000     000     
    #  0000000   0000000   000   000      0      00000000  000   000     000     
    
    convertDots: (dots, type) ->
        
        points = @points()
        
        indexDots = @indexDots dots
            
        for idots in indexDots
            
            index = idots.index
            point = points[index]
            
            continue if index == 0
            
            thisp = @dotPos index
            prevp = @dotPos index-1
            
            switch type
                
                when 'C' 
                    
                    switch point[0]
                        when 'C' then continue
                        when 'Q', 'S' 
                            ctrl = pos point[1], point[2]
                            mid1 = prevp.plus (prevp.to ctrl).scale 0.666
                            mid2 = thisp.plus (thisp.to ctrl).scale 0.666
                            point.splice 1, 2, mid1.x, mid1.y, mid2.x, mid2.y
                        when 'M', 'L' 
                            mid1 = prevp.plus (prevp.to thisp).scale 0.333
                            mid2 = prevp.plus (prevp.to thisp).scale 0.666
                            point.splice 1, 0, mid1.x, mid1.y, mid2.x, mid2.y
                            
                    point[0] = 'C'
                    
                when 'Q'
                    
                    switch point[0]
                        when 'Q' then continue
                        when 'C' 
                            midp = @dotPos(index, 'ctrl1').mid @dotPos(index, 'ctrl2')
                            point.splice 1, 4, midp.x, midp.y
                        when 'M', 'L' 
                            midp = prevp.mid thisp 
                            point.splice 1, 0, midp.x, midp.y
                            
                    point[0] = 'Q'
                    
                when 'S'
                    
                    switch point[0]
                        when 'S' then continue
                        when 'C' 
                            midp = @dotPos(index, 'ctrl1').mid @dotPos(index, 'ctrl2')
                            point.splice 1, 4, midp.x, midp.y
                        when 'M', 'L' 
                            midp = prevp.mid thisp 
                            point.splice 1, 0, midp.x, midp.y
                            
                    point[0] = 'S'
                    
            @initCtrlDots   index, point
            @updateCtrlDots index, point
            
        @plot()
                
    # 00     00   0000000   000   000  00000000  00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000   000  000       000   000  000   000  000  0000  000     000     
    # 000000000  000   000   000 000   0000000   00000000   000   000  000  000 0 000     000     
    # 000 0 000  000   000     000     000       000        000   000  000  000  0000     000     
    # 000   000   0000000       0      00000000  000         0000000   000  000   000     000     

    
    movePoint: (index, stagePos, dots=['point']) ->
        
        itemPos = @trans.inverse @item, stagePos
        
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
                                
                    if @isPath() and not @edit.passive and index == @numPoints()-1
                        
                        firstPoint = @pointAt 0
                        firstPoint[1] = itemPos.x
                        firstPoint[2] = itemPos.y
                        
                        @updateCtrlDots 0, firstPoint
                        @updateCtrlDots 1, @pointAt 1 if points.length>1

                when 'ctrl1', 'ctrlq', 'ctrls'
                    point[1] = itemPos.x
                    point[2] = itemPos.y

                when 'ctrl2'
                    point[3] = itemPos.x
                    point[4] = itemPos.y
                    
                when 'ctrlr'
                    ppos = @dotPos index
                    refl = ppos.minus ppos.to stagePos
                    @movePoint index, refl, 'ctrls'
                    
        @updateCtrlDots index, point
        
        if point[0] in ['Q', 'M', 'L', 'C'] and index < @numPoints()-1
            @updateCtrlDots index+1, @pointAt index+1
         
    #  0000000   0000000    0000000    00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000   000  000   000  000   000  000  0000  000     000     
    # 000000000  000   000  000   000  00000000   000   000  000  000 0 000     000     
    # 000   000  000   000  000   000  000        000   000  000  000  0000     000     
    # 000   000  0000000    0000000    000         0000000   000  000   000     000     
    
    addPoint: (index, stagePos, code) ->
        
        itemPos = @trans.inverse @item, stagePos
        
        points = @points()
        point  = switch code
            when 'S', 'Q'
                [code, stagePos.x, stagePos.y, stagePos.x, stagePos.y]
            when 'C'
                [code, stagePos.x, stagePos.y, stagePos.x, stagePos.y, stagePos.x, stagePos.y]
            else
                [itemPos.x, itemPos.y]
                
        points.splice index, 0, point
        
        @initCtrlDots   index, point
        @updateCtrlDots index, point
    
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
        
        indexDots = @indexDots(dots).map (idots) -> index:idots.index, dots:idots.dots.map (dot) -> dot.dot
        
        for indots in indexDots
            log indots.index, indots.dots
        
        for indots in indexDots
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

    plot: (points=@item.array()) -> @item.plot points

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
                indexDots.push index:index, dots:idots
        indexDots
        
    dotPos: (index, dot='point') ->
        
        index = @numPoints() + index if index < 0
        
        if d = @ctrls[index]?.dots[dot]
            pos d.cx(), d.cy()
        else
            log "no dot #{dot} at index #{index}?"
    
    points: -> @item.array().valueOf()
    numPoints: -> @points().length
    pointAt: (index) -> @points()[index]
    pointCode: (index) ->
        if @isPoly()
            'P'
        else
            @pointAt(index)[0]
                
    isPoly: -> @item.type in ['polygon', 'polyline', 'line']
    isPath: -> not @isPoly()

module.exports = Object

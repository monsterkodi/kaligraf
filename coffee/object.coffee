
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
            
            for idots in indexDots
                
                has = (type) -> not empty idots.dots.filter (dot) -> dot.dot == type
                add = (type) => dot = @ctrls[idots.index].dots[type]; idots.dots.push dot if dot not in idots.dots 
                    
                if has 'point'
                    switch @pointCode idots.index
                        when 'S' then add 'ctrls'
                        when 'Q' then add 'ctrlq'
                        when 'C' then add 'ctrl2'
        
        for idots in indexDots
            
            for dot in idots.dots
                oldPos = @dotPos idots.index, dot.dot
                newPos = oldPos.plus delta
                @movePoint idots.index, newPos, dot.dot
            
        @plot()
                            
    # 00     00   0000000   000   000  00000000  00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000   000  000       000   000  000   000  000  0000  000     000     
    # 000000000  000   000   000 000   0000000   00000000   000   000  000  000 0 000     000     
    # 000 0 000  000   000     000     000       000        000   000  000  000  0000     000     
    # 000   000   0000000       0      00000000  000         0000000   000  000   000     000     

    
    movePoint: (index, viewPos, dots=['point']) ->
        
        itemPos = @trans.inverse @item, @stage.stageForView viewPos
        
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
                    refl = ppos.minus ppos.to viewPos
                    @movePoint index, refl, 'ctrls'
                    
        @updateCtrlDots index, point
        
        if point[0] in ['Q', 'M', 'L', 'C'] and index < @numPoints()-1
            @updateCtrlDots index+1, @pointAt index+1
         
    #  0000000   0000000    0000000    00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000   000  000   000  000   000  000  0000  000     000     
    # 000000000  000   000  000   000  00000000   000   000  000  000 0 000     000     
    # 000   000  000   000  000   000  000        000   000  000  000  0000     000     
    # 000   000  0000000    0000000    000         0000000   000  000   000     000     
    
    addPoint: (index, viewPos, code) ->
        
        itemPos = @trans.inverse @item, @stage.stageForView viewPos
        
        points = @points()
        point  = switch code
            when 'S', 'Q'
                [code, viewPos.x, viewPos.y, viewPos.x, viewPos.y]
            when 'C'
                [code, viewPos.x, viewPos.y, viewPos.x, viewPos.y, viewPos.x, viewPos.y]
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
        
        for indexDots in @indexDots dots
            @delIndexDots indexDots.index, indexDots.dots
        
    delIndexDots: (index, dots) ->
        
        dotNames = dots.map (dot) -> dot.dot
        
        if 'point' in dotNames
            @delPoint index
            return
            
        points = @points()
        point = points[index]
        
        if dotNames.length > 1
            if 'ctrl1' in dotNames and 'ctrl2' in dotNames
                point[0] = 'L'
                point.splice 1, 4
            else if 'ctrlr' in dotNames
                point[0] = 'L'
                point.splice 1, 2
            else
                log '???', dotNames
        else
            switch dotNames[0]
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
            ctrl.moveBy delta

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

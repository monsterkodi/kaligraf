
#  0000000   0000000          000  00000000   0000000  000000000
# 000   000  000   000        000  000       000          000
# 000   000  0000000          000  0000000   000          000
# 000   000  000   000  000   000  000       000          000
#  0000000   0000000     0000000   00000000   0000000     000

{ pos, log, _ } = require 'kxk'

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
        
        points = @item.array().valueOf()

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
        
        ctrl.createDot 'point'
        
        switch point[0]
            when 'S' 
                ctrl.createDot 'ctrls'
                ctrl.createDot 'ctrlr'
            when 'C'
                ctrl.createDot 'ctrl1'
                ctrl.createDot 'ctrl2'
            when 'Q'
                ctrl.createDot 'ctrlq'

    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    updateCtrlDots: (index, point) ->
        
        ctrl = @ctrls[index]
        ctrl.updateDot 'point', point
        
        switch point[0]
            when 'S' 
                ctrl.updateDot 'ctrls', point
                ctrl.updateDot 'ctrlr', point
            when 'C'
                ctrl.updateDot 'ctrl1', point
                ctrl.updateDot 'ctrl2', point
            when 'Q'
                ctrl.updateDot 'ctrlq', point
                
    updatePos: ->

        points = @item.array().valueOf()

        for i in [0...points.length]
            
            @updateCtrlDots i, points[i]
                
    # 00     00   0000000   000   000  00000000  00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000   000  000       000   000  000   000  000  0000  000     000     
    # 000000000  000   000   000 000   0000000   00000000   000   000  000  000 0 000     000     
    # 000 0 000  000   000     000     000       000        000   000  000  000  0000     000     
    # 000   000   0000000       0      00000000  000         0000000   000  000   000     000     
    
    movePoint: (index, viewPos, dots=['point']) ->
        
        itemPos = @trans.inverse @item, @stage.stageForView viewPos
        
        point = @pointAt index
        
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
                                points = @points()
                                point  = points[index]
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
                    ppos = @dotPos index
                    refl = ppos.minus ppos.to viewPos
                    @movePoint index, refl, 'ctrls'
                    
        @updateCtrlDots index, point
        
        if point[0] in ['Q', 'M', 'C'] and index < @numPoints()-1
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
        
        @initCtrlDots index, point
    
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
        @plot()
        
    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveCtrlsBy: (delta) ->

        for ctrl in @ctrls
            ctrl.moveBy delta

    plot: -> @item.plot @item.array()

    dotPos: (index, dot='point') ->
        
        if d = @ctrls[index]?.dots[dot]
            pos d.cx(), d.cy()
        else
            log "no dot #{dot} at index #{index}?"
    
    points: -> @item.array().valueOf()
    numPoints: -> @points().length
    pointAt: (i) -> @points()[i]

    isPoly: -> @item.type in ['polygon', 'polyline', 'line']
    isPath: -> not @isPoly()

module.exports = Object

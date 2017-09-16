
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

        @edit  = @object.edit
        @stage = @edit.stage
        @trans = @edit.trans

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        for k,d of @dots
            delete d.ctrl
            delete d.dot
            d.remove()
            
        for k,l of @lines
            l.remove()

        @dots  = {}
        @lines = {}

    # 0000000     0000000   000000000
    # 000   000  000   000     000
    # 000   000  000   000     000
    # 000   000  000   000     000
    # 0000000     0000000      000

    initDots: (point) ->
        
        @del()
        @createDot 'point'
        
        switch point[0]
            when 'S' 
                @createDot 'ctrls'
                @createDot 'ctrlr'
            when 'C'
                @createDot 'ctrl1'
                @createDot 'ctrl2'
            when 'Q'
                @createDot 'ctrlq'

    updateDots: (point) ->

        @updateDot 'point', point
        
        switch point[0]
            when 'S' 
                @updateDot 'ctrls', point
                @updateDot 'ctrlr', point
            when 'C'
                @updateDot 'ctrl1', point
                @updateDot 'ctrl2', point
            when 'Q'
                @updateDot 'ctrlq', point
        
    #  0000000  00000000   00000000   0000000   000000000  00000000  
    # 000       000   000  000       000   000     000     000       
    # 000       0000000    0000000   000000000     000     0000000   
    # 000       000   000  000       000   000     000     000       
    #  0000000  000   000  00000000  000   000     000     00000000  
    
    createDot: (dot) ->
  
        svg = @edit.svg.use @edit.defs[@pointCode()]
            
        svg.addClass "#{dot}Dot"
        svg.ctrl = @
        svg.dot  = dot

        @dots[dot] = svg
        
        if dot in ['ctrl1', 'ctrl2', 'ctrlq', 'ctrlr', 'ctrls']
            
            @createLine dot
            
        if dot == 'ctrlq'
            
            @createLine 'ctrlq2'

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
            else
                log 'dafuk?'
        
        dotPos = @trans.transform @object.item, itemPos
        
        # log "updateDot #{dot}", svg.type, svg.cx(), svg.cy(), dotPos
        
        svg.cx dotPos.x
        svg.cy dotPos.y

        pointPos = @trans.transform @object.item, pos point[point.length-2], point[point.length-1]
        
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

        @lines[dot]     = @edit.linesWhite.line()
        @lines[dot+'_'] = @edit.linesBlack.line()
        
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
            @dots[dot]?.addClass 'selected'
        else
            @dots[dot]?.removeClass 'selected'
            
    isSelected: (dot) -> @dots[dot]?.hasClass 'selected'
                
    # 00     00   0000000   000   000  00000000  0000000    000   000  
    # 000   000  000   000  000   000  000       000   000   000 000   
    # 000000000  000   000   000 000   0000000   0000000      00000    
    # 000 0 000  000   000     000     000       000   000     000     
    # 000   000   0000000       0      00000000  0000000       000     
    
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
    pointCode: -> @object.pointCode @index()

module.exports = Ctrl

#  0000000  000000000  00000000   000    
# 000          000     000   000  000    
# 000          000     0000000    000    
# 000          000     000   000  000    
#  0000000     000     000   000  0000000

{ drag, last, pos, log, _ } = require 'kxk'

class Ctrl

    constructor: (@item) ->
                
        @dots  = {}
        @lines = {}
        @drags = []
        
        @edit  = @item.edit
        @kali  = @edit.kali
        @trans = @kali.trans
        
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
    
    createDot: (type, stagePos) ->

        clss = type == 'point' and 'editPoint' or 'editCtrl'
        dot = @edit.svg.circle(@edit.dotSize).addClass clss
        dot.style cursor: 'pointer'
        dot.remember 'ctrl',  @

        @dots[type] = dot

        if type in ['ctrl1', 'ctrlr', 'ctrl2']
            @createLine type

        @drags.push new drag
            target:  dot.node
            onStart: @onStart
            onMove:  @onMove
            onStop:  @onStop

        last(@drags).type = type
        
        dot

    # 000      000  000   000  00000000  
    # 000      000  0000  000  000       
    # 000      000  000 0 000  0000000   
    # 000      000  000  0000  000       
    # 0000000  000  000   000  00000000  
    
    createLine: (type) ->
        
        line = @edit.svg.line()
        line.addClass "editLine"
        line.addClass "#{type}Line"
        line.back()
        @lines[type] = line

    updateLine: (type) ->
         
        if line = @lines[type]
            cpos = @getPos type
            ppos = @getPos 'point'
            line.plot [[ppos.x, ppos.y], [cpos.x, cpos.y]]
        else if type == 'point'
            @updateLine 'ctrl1'
            @updateLine 'ctrl2'
            @updateLine 'ctrlr'
         
    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    onStart: (drag, event) => 
    onStop:  (drag, event) =>
    onMove:  (drag, event) =>

        stagePos = @kali.stage.stageForEvent pos event

        type = drag.type
        
        @setPos type, stagePos, not event.shiftKey
        
        @item.plot()

    moveBy: (delta) -> @setPos 'point', @getPos('point').plus(delta), true

    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
    index:     -> @item.ctrls.indexOf @
    itemPoint: -> @item.elem.array().valueOf()[@index()]        
        
    # 00000000    0000000    0000000  
    # 000   000  000   000  000       
    # 00000000   000   000  0000000   
    # 000        000   000       000  
    # 000         0000000   0000000   

    getPos: (type) ->

        if dot = @dots[type] ? @lines[type]
            pos dot.cx(), dot.cy()
                
    setPos: (type, stagePos, moveAll) ->
        
        dot = @dots[type]
        
        if not dot?
            log 'no dot?', type
            return

        oldPos = @getPos 'point'
        
        dot.cx stagePos.x
        dot.cy stagePos.y

        @setSmoothPos type, stagePos
        @updateLine   type, stagePos
        @setElemPos   type, @trans.inverse @item.elem, stagePos
        
        if moveAll and type == 'point' and @dots['ctrl1']
            @setPos 'ctrl1', @getPos('ctrl1').plus oldPos.to stagePos
                        
    #  0000000  00     00   0000000    0000000   000000000  000   000  
    # 000       000   000  000   000  000   000     000     000   000  
    # 0000000   000000000  000   000  000   000     000     000000000  
    #      000  000 0 000  000   000  000   000     000     000   000  
    # 0000000   000   000   0000000    0000000      000     000   000  
    
    setSmoothPos: (type, stagePos) ->
        
        switch type
            when 'ctrl1' then sibling = 'ctrlr'
            when 'ctrlr' then sibling = 'ctrl1'
            when 'point' then sibling = 'ctrlr'; stagePos = @getPos 'ctrl1'
            else 
                return

        if dot = @dots[sibling]
            
            refl = @item.reflPos @index(), sibling
            
            dot.cx refl.x
            dot.cy refl.y
                
            @updateLine sibling, refl
                    
    # 00000000  000      00000000  00     00  
    # 000       000      000       000   000  
    # 0000000   000      0000000   000000000  
    # 000       000      000       000 0 000  
    # 00000000  0000000  00000000  000   000  
    
    setElemPos: (type, elemPos) ->
        
        if @item.elem.type in ['polygon', 'polyline', 'line']

            @setPolyPos type, elemPos
        
        else
            
            switch type
                
                when 'point'          then @setPointPos type, elemPos
                when 'ctrl1', 'ctrl2' then @setCtrlPos  type, elemPos
                when 'ctrlr'
                    stageRefl = @item.reflPos @index(), 'ctrl1'
                    refl = @trans.inverse @item.elem, stageRefl
                    @setCtrlPos  'ctrl1', refl 
                
    # 00000000    0000000   000      000   000  
    # 000   000  000   000  000       000 000   
    # 00000000   000   000  000        00000    
    # 000        000   000  000         000     
    # 000         0000000   0000000     000     
    
    setPolyPos: (type, elemPos) ->

        point  = @itemPoint()
        point[0] = elemPos.x
        point[1] = elemPos.y
        
    #  0000000  000000000  00000000   000      
    # 000          000     000   000  000      
    # 000          000     0000000    000      
    # 000          000     000   000  000      
    #  0000000     000     000   000  0000000  
    
    setCtrlPos:  (type, elemPos) ->  
        
        return if not elemPos?
        
        point = @itemPoint()
        
        switch point[0]
            
            when 'C', 'c', 'S', 's', 'Q', 'q'
    
                point[1] = elemPos.x
                point[2] = elemPos.y
        
    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
    setPointPos: (type, elemPos) ->   
        
        point = @itemPoint()
        
        if point[0] in ['C', 'c', 'S', 's', 'Q', 'q', 'M', 'm', 'L', 'l']
            
            point[point.length-2] = elemPos.x
            point[point.length-1] = elemPos.y

module.exports = Ctrl

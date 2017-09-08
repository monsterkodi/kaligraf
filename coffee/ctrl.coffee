
#  0000000  000000000  00000000   000    
# 000          000     000   000  000    
# 000          000     0000000    000    
# 000          000     000   000  000    
#  0000000     000     000   000  0000000

{ drag, last, pos, log, _ } = require 'kxk'

class Ctrl

    constructor: (@item, @index) ->
                
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

    #  0000000   0000000    0000000        000000000  000   000  00000000   00000000  
    # 000   000  000   000  000   000         000      000 000   000   000  000       
    # 000000000  000   000  000   000         000       00000    00000000   0000000   
    # 000   000  000   000  000   000         000        000     000        000       
    # 000   000  0000000    0000000           000        000     000        00000000  
    
    addType: (type, stagePos) -> 
        
        @createDot type
        
        if stagePos? then @setPos type, stagePos
        
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
        
        @item.elem.plot @item.elem.array()        

    moveBy: (delta) ->  
    
        @setPos 'point', @getPos('point').plus(delta), true
        @item.elem.plot @item.elem.array()
        
    # 00000000    0000000   000  000   000  000000000  
    # 000   000  000   000  000  0000  000     000     
    # 00000000   000   000  000  000 0 000     000     
    # 000        000   000  000  000  0000     000     
    # 000         0000000   000  000   000     000     
    
    itemPoint: -> @item.elem.array().valueOf()[@index]        
        
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

        if moveAll and type == 'point' and @dots['ctrl1']
            delta = stagePos.minus @getPos 'point' 
            @setPos 'ctrl1', stagePos.plus delta

        dot.cx stagePos.x
        dot.cy stagePos.y
            
        @setElemPos   type, @trans.inverse @item.elem, stagePos
        @updateLine   type, stagePos
        @setSmoothPos type, stagePos
                
    #  0000000  00     00   0000000    0000000   000000000  000   000  
    # 000       000   000  000   000  000   000     000     000   000  
    # 0000000   000000000  000   000  000   000     000     000000000  
    #      000  000 0 000  000   000  000   000     000     000   000  
    # 0000000   000   000   0000000    0000000      000     000   000  
    
    setSmoothPos: (type, stagePos) ->
        
        switch type
            when 'ctrl1' then sibling = 'ctrlr'
            when 'ctrlr' then sibling = 'ctrl1'
            else 
                return
                    
        if dot = @dots[sibling]
            pp = @getPos 'point'
            reflected = pp.plus pp.minus stagePos
            dot.cx reflected.x
            dot.cy reflected.y
            @updateLine sibling, reflected
                    
    # 00000000  000      00000000  00     00  
    # 000       000      000       000   000  
    # 0000000   000      0000000   000000000  
    # 000       000      000       000 0 000  
    # 00000000  0000000  00000000  000   000  
    
    setElemPos: (type, elemPos) ->
        
        if @item.type in ['polygon', 'polyline', 'line']

            @setPolyPos type, elemPos
        
        else
            
            switch type
                
                when 'ctrl1', 'ctrl2' then @setCtrlPos  type, elemPos
                when 'point'          then @setPointPos type, elemPos
                
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

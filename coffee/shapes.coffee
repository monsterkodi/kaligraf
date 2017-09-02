
#  0000000  000   000   0000000   00000000   00000000   0000000
# 000       000   000  000   000  000   000  000       000     
# 0000000   000000000  000000000  00000000   0000000   0000000 
#      000  000   000  000   000  000        000            000
# 0000000   000   000  000   000  000        00000000  0000000 

{ last, pos, log } = require 'kxk'

{ boxCenter } = require './utils'

class Shapes

    constructor: (@kali) ->
        
        @stage = @kali.stage
        @tools = @kali.tools
        @trans = @kali.trans
        
        @svg       = @stage.svg
        @selection = @stage.selection

    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape, stagePos, attr, style) ->
        
        switch shape 
            
            when 'triangle'
                
                e = @svg.polygon '-50,50 0,-50 50,50'
                
            when 'line', 'polyline', 'polygon'
                
                e = @svg[shape]()
                e.plot [[stagePos.x, stagePos.y], [stagePos.x, stagePos.y]]
                
            when 'text'
                # e = @svg.text 'Hy!'
                e = @svg.text 'Hy!\nWorld\n.oOXOo.'
                e.font 'size', 100
                # e.font 'anchor', 'middle'
                
            else
                e = @svg[shape]()
                
        e.style
            stroke:           @tools.stroke.color
            'stroke-opacity': @tools.stroke.alpha
            'stroke-width':   @tools.width.width
            
        if shape not in ['polyline', 'line']
            e.style
                fill:           @tools.fill.color
                'fill-opacity': @tools.fill.alpha
        else
            e.style 
                fill:           'none'
                'fill-opacity': 0.0
            
        e.attr  attr  if attr?
        e.style style if style?
        e
        
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    onStart: (drag, event) => @handleMouseDown event
    
    handleMouseDown: (event) =>
        
        @kali.focus()
        @tools.collapseTemp()
        
        shape = @kali.shapeTool()
        
        for s,k of {pick:event.metaKey, pan:event.altKey, loupe:event.ctrlKey}
            if k and shape != s
                @tools[s].onClick()
                shape = s
        
        eventPos = @eventPos event 
        stagePos = @stagePos event
                
        switch shape
            
            when 'pick'

                e = @stage.itemAtPos eventPos
                
                if not e?
                    # log 'ADOPT!!!', event.target.id
                    e = SVG.adopt event.target
                    
                if e == @svg
                    if not event.shiftKey
                        @selection.clear()
                    @selection.start @eventPos(event), join:event.shiftKey
                else
                    if not @selection.contains e
                        if not event.shiftKey
                            @selection.clear()
                        @selection.pos = @eventPos(event)
                        @selection.add e
                    else
                        if event.shiftKey
                            @selection.del e
                            
            when 'loupe' 
                
                @selection.loupe = @selection.addRect 'loupeRect'
                
            when 'pan' then
            else
                @selection.clear()
                
                if @drawing? and shape in ['line', 'polygon', 'polyline']
                    switch shape
                        when 'polygon', 'polyline' 
                            @addPolyPoint stagePos
                        when 'line'                
                            @setLinePoint stagePos
                            delete @drawing
                    return
                        
                @drawing = @addShape shape, stagePos
                
                if shape not in ['line', 'polygon', 'polyline']
                    @trans.center @drawing, stagePos

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onMove: (drag, event) =>

        shape = @kali.shapeTool()
        
        stagePos = @stagePos event
        
        switch shape
            
            when 'pan'   
                
                @stage.panBy drag.delta
                
            when 'loupe' 
                
                r = x:drag.startPos.x, y:drag.startPos.y, x2:drag.pos.x, y2:drag.pos.y                
                @selection.setRect @selection.loupe, r
                
            when 'pick'
                
                if @selection.rect?
                    @selection.move @eventPos(event), join:event.shiftKey

            when 'line' 
                
                @setLinePoint stagePos
                                
            when 'polygon', 'polyline'
                
                @addPolyPoint stagePos
                
            else
                
                @trans.width  @drawing, drag.deltaSum.x
                @trans.height @drawing, drag.deltaSum.y
                
                switch shape
                    when 'ellipse', 'circle'
                        s = @trans.size @drawing
                        c = drag.startPos.minus(@stage.viewPos).plus(s.scale 0.5)
                        @trans.center @drawing, c

    setLinePoint: (p) ->
        
        arr = @drawing.array().valueOf()
        last(arr)[0] = p.x
        last(arr)[1] = p.y
        @drawing.plot arr
        
    addPolyPoint: (p) ->
        
        arr  = @drawing.array().valueOf()
        tail = arr.length > 1 and arr[arr.length-2] or arr[arr.length-1]
        dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
        if arr.length < 2 or dist > 20
            arr.push [p.x, p.y]
        else
            last(arr)[0] = p.x
            last(arr)[1] = p.y
        @drawing.plot arr
                        
    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onStop: (drag, event) =>
        
        eventPos = @eventPos event
        stagePos = @stagePos event
        
        if @selection.rect?
            @selection.end eventPos
            return
        
        shape = @kali.shapeTool() 
            
        switch shape
            
            when 'loupe' 
                
                @selection.loupe.remove()
                delete @selection.loupe
                @stage.loupe drag.startPos, drag.pos

        if @drawing
            
            zero = false
            
            if @trans.width(@drawing) == 0

                switch shape
                    when 'text' then
                    when 'line', 'polygon', 'polyline'
                        @drawing.remember 'isPickPoly', true
                        return
                    when 'ellipse'
                        @drawing.width 50
                    else
                        @drawing.width 100
                zero = true    
                
            if @trans.height(@drawing) == 0

                switch shape
                    when 'text' then
                    else
                        @drawing.height 100
                zero = true       
                
            if zero
                
                if shape == 'rect'
                    stagePos.sub pos 50, 50
                    
                @trans.center @drawing, stagePos
            
            if not @drawing.remember 'isPickPoly'
                
                @endDrawing()

    endDrawing: ->
        
        if @drawing

            if @trans.width(@drawing) == 0 or @trans.height(@drawing) == 0

                @drawing.remove()
                
            else
                shape = @kali.shapeTool() 
                switch shape
                    when 'line', 'polygon', 'polyline'

                        c = boxCenter @drawing.bbox()
                        @drawing.center 0, 0
                        @kali.trans.center @drawing, c
                
            delete @drawing

    # 00000000    0000000    0000000  
    # 000   000  000   000  000       
    # 00000000   000   000  0000000   
    # 000        000   000       000  
    # 000         0000000   0000000   
    
    eventPos: (event) -> @stage.eventPos event
    stagePos: (event) -> @stage.stagePos event
            
module.exports = Shapes

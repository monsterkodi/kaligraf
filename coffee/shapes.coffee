
#  0000000  000   000   0000000   00000000   00000000   0000000
# 000       000   000  000   000  000   000  000       000     
# 0000000   000000000  000000000  00000000   0000000   0000000 
#      000  000   000  000   000  000        000            000
# 0000000   000   000  000   000  000        00000000  0000000 

{ last, log } = require 'kxk'

class Shapes

    constructor: (@kali) ->
        
        @stage = @kali.stage
        @tools = @kali.tools
        
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
                @drawing.cx stagePos.x
                @drawing.cy stagePos.y

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
                
                @drawing.width  drag.deltaSum.x
                @drawing.height drag.deltaSum.y
                
                switch shape
                    when 'ellipse', 'circle'
                        @drawing.cx drag.startPos.x - @stage.viewPos().x + @drawing.width()/2
                        @drawing.cy drag.startPos.y - @stage.viewPos().y + @drawing.height()/2

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
            
            if @drawing.width() == 0
                
                switch shape
                    when 'line', 'polygon', 'polyline'
                        @drawing.remember 'isPickPoly', true
                        return
                    when 'ellipse'
                        @drawing.width 50
                    when 'text' then
                    else
                        @drawing.width 100
                    
                @drawing.cx stagePos.x
                
                switch shape
                    when 'circle'
                        @drawing.cy stagePos.y
                    
            if @drawing.height() == 0
                
                switch shape
                    when 'text' then
                    else
                        @drawing.height 100
                        
                @drawing.cy stagePos.y
            
            if not @drawing.remember 'isPickPoly'
                
                delete @drawing

    endDrawing: ->
        
        if @drawing
            
            if @drawing.width() == 0 or @drawing.height() == 0
                @drawing.remove()
                
            delete @drawing

    # 00000000    0000000    0000000  
    # 000   000  000   000  000       
    # 00000000   000   000  0000000   
    # 000        000   000       000  
    # 000         0000000   0000000   
    
    eventPos: (event) -> @stage.eventPos event
    stagePos: (event) -> @stage.stagePos event
            
module.exports = Shapes

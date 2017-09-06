
#  0000000  000   000   0000000   00000000   00000000   0000000
# 000       000   000  000   000  000   000  000       000     
# 0000000   000000000  000000000  00000000   0000000   0000000 
#      000  000   000  000   000  000        000            000
# 0000000   000   000  000   000  000        00000000  0000000 

{ post, last, resolve, pos, log } = require 'kxk'

{ boxCenter } = require './utils'

Poly = require './poly'
Path = require './path'

class Shapes

    constructor: (@kali) ->
        
        @stage = @kali.stage
        @tools = @kali.tools
        @trans = @kali.trans
        
        @poly = new Poly @kali
        @path = new Path @kali
        
        @svg       = @stage.svg
        @selection = @stage.selection

    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape, stagePos) ->
        
        switch shape 
            
            when 'triangle'
                
                e = @svg.polygon '-0.50,0.50 0,-0.50 0.50,0.50'

            when 'triangle_square'
                
                e = @svg.polygon '0,0 1,1 0,1'
                
            when 'line', 'polyline', 'polygon'
                
                e = @svg[shape]()
                e.plot [[stagePos.x, stagePos.y], [stagePos.x, stagePos.y]]
                
            when 'bezier', 'bezier_quad'
                
                a = new SVG.PathArray [ ['M', stagePos.x, stagePos.y] ]
                e = @svg.path()
                e.plot a
                
            when 'pie' 
                e = @svg.path 'M0,0 h1 a1,1 0 1,1 -1,-1,z'
                
            when 'arc'
                e = @svg.path 'M0,0 a1,1 0 0,0 -1,-1'
                
            when 'text'
                
                e = @svg.text 'kaligraf'
                e.font 'size', 100
                
            when 'image'
                
                e = @svg.image 'file://' + resolve '~/Desktop/kaligraf.png'
                e.loaded (loader) ->
                    @size loader.width, loader.height
                
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
        
        @handler = switch @kali.shapeHandler()
            
            when 'poly' then @poly
            when 'path' then @path
            else null
        
        for s,k of {pick:event.shiftKey, pan:event.metaKey, loupe:event.ctrlKey, pipette:event.altKey}
            if k and shape != s
                @tools[s].onClick()
                shape = s
        
        eventPos = pos event 
        stagePos = @kali.stage.stageForEvent eventPos
                
        switch shape
            
            when 'pick'

                e = @stage.itemAtPos eventPos
                
                if e == @svg or not e?
                    if not event.shiftKey
                        @selection.clear()
                    @selection.start eventPos, join:event.shiftKey
                else
                    if not @selection.contains e
                        if not event.shiftKey
                            @selection.clear()
                        @selection.pos = eventPos
                        @selection.add e
                    else
                        if event.shiftKey
                            @selection.del e
                            
            when 'pipette'
                
                e = @stage.itemAtPos eventPos
                if e? and e != @svg
                    
                    @kali.tools.fill.color = e.style('fill')
                    @kali.tools.fill.alpha = e.style('fill-opacity')
                    @kali.tools.fill.update()
                    post.emit 'color', 'fill', 'color', @kali.tools.fill.color
                    
                    @kali.tools.stroke.color = e.style('stroke')
                    @kali.tools.stroke.alpha = e.style('stroke-opacity')
                    @kali.tools.stroke.update()
                    post.emit 'color', 'stroke', 'color', @kali.tools.stroke.color
                    
                    @kali.tools.width.setWidth e.style('stroke-width')
                
            when 'loupe' 
                
                @selection.loupe = @selection.addRect 'loupeRect'
                
            when 'pan' then
            else
                @selection.clear()
  
                if @drawing? and @handler?.handleDown event, stagePos
                    if not @handler.continuePicking()
                        @endDrawing()
                    return
                        
                @drawing = @addShape shape, stagePos
                
                if @handler
                    @handler.startDrawing @drawing, shape, stagePos
                else
                    @trans.pos @drawing, stagePos

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onMove: (drag, event) =>

        shape = @kali.shapeTool()
        
        eventPos = pos event
        stagePos = @kali.stage.stageForEvent eventPos
        
        if @handler? 
            if @handler.handleDrag event, stagePos
                return
        
        switch shape
            
            when 'pipette' then
                    
            when 'pan'   
                
                @stage.panBy drag.delta
                
            when 'loupe' 
                
                r = x:drag.startPos.x, y:drag.startPos.y, x2:drag.pos.x, y2:drag.pos.y                
                @selection.setRect @selection.loupe, r
                @kali.stage.setCursor 'zoom-in'
                
            when 'pick'
                
                if @selection.rect?
                    @selection.move eventPos, join:event.shiftKey
                
            else
                z  = @kali.stage.zoom
                p1 = @kali.stage.stageForEvent drag.startPos
                p2 = @kali.stage.stageForEvent drag.pos
                @trans.setRect @drawing, x:p1.x, y:p1.y, x2:p2.x, y2:p2.y
                                            
    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onStop: (drag, event) =>
        
        eventPos = pos event
        stagePos = @kali.stage.stageForEvent eventPos
        
        if @selection.rect?
            @selection.end eventPos
            return
        
        shape = @kali.shapeTool() 
            
        switch shape
            
            when 'loupe' 
                
                @selection.loupe.remove()
                delete @selection.loupe
                @stage.loupe drag.startPos, drag.pos
                @stage.setCursor @kali.tools.ctrlDown and 'zoom-out' or 'zoom-in'

        if @drawing

            if drag.startPos == drag.lastPos
                
                if @handler?.handlePick stagePos
                    return

                switch shape
                    when 'text' then
                    when 'ellipse'
                        @drawing.size 50, 100
                        @trans.center @drawing, stagePos
                    else
                        @drawing.size 100, 100
                        @trans.center @drawing, stagePos
                
            if not @handler? or @handler.handleStop event, stagePos 
                
                @endDrawing drag, event, stagePos

    endDrawing: ->
        
        if @drawing

            if @trans.width(@drawing) == 0 and @trans.height(@drawing) == 0

                @drawing.remove()
                
            else            
                @stage.selection.set [@drawing]
                
            @handler?.endDrawing()
            @handler = null
            delete @drawing

module.exports = Shapes

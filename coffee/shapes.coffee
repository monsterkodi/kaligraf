
#  0000000  000   000   0000000   00000000   00000000   0000000
# 000       000   000  000   000  000   000  000       000     
# 0000000   000000000  000000000  00000000   0000000   0000000 
#      000  000   000  000   000  000        000            000
# 0000000   000   000  000   000  000        00000000  0000000 

{ post, drag, last, resolve, pos, log, _ } = require 'kxk'

Draw = require './draw'
Edit = require './edit'
Text = require './text'

class Shapes

    constructor: (@kali) ->
        
        @stage = @kali.stage
        @tools = @kali.tools
        @trans = @kali.trans
        
        @svg       = @stage.svg
        @selection = @stage.selection
        @resizer   = @stage.resizer
        
        @drag = new drag
            target:  @stage.element
            onStart: @onStart
            onMove:  @onDrag
            onStop:  @onStop
        
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
                
            when 'bezier', 'bezier_quad', 'bezier_cube'

                arr = [ ['M', stagePos.x, stagePos.y] ]
                arr.push switch shape
                    when 'bezier'      then ['S', stagePos.x, stagePos.y, stagePos.x, stagePos.y]
                    when 'bezier_quad' then ['Q', stagePos.x, stagePos.y, stagePos.x, stagePos.y]
                    when 'bezier_cube' then ['C', stagePos.x, stagePos.y, stagePos.x, stagePos.y, stagePos.x, stagePos.y]
                a = new SVG.PathArray arr
                e = @svg.path()
                e.plot a

            when 'pie' 
                e = @svg.path 'M0,0 h1 a1,1 0 1,1 -1,-1,z'
                
            when 'arc'
                e = @svg.path 'M0,0 a1,1 0 0,0 -1,-1'
                
            when 'text'
                
                e = @svg.text 'text'
                e.leading 1.15
                e.font 'size', 100
                e.font 'weight', @kali.tools.font.weight
                e.font 'style',  @kali.tools.font.style
                e.font 'family', @kali.tools.font.family
                
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
    
    onStart: (drag, event) => 

        @clearText()
        
        shape = @kali.shapeTool()
        if shape == 'text'
            if item = @stage.itemAtPos pos event
                if item.type == 'text'
                    @editTextItem item
                    return
                            
        @handleMouseDown event
        
    # 000000000  00000000  000   000  000000000  
    #    000     000        000 000      000     
    #    000     0000000     00000       000     
    #    000     000        000 000      000     
    #    000     00000000  000   000     000     
    
    editTextItem: (item) -> @text = new Text @kali, item
        
    clearText: ->
        
        @text?.del()
        delete @text
        
    #  0000000  000   000  000  000000000   0000000  000   000  
    # 000       000 0 000  000     000     000       000   000  
    # 0000000   000000000  000     000     000       000000000  
    #      000  000   000  000     000     000       000   000  
    # 0000000   00     00  000     000      0000000  000   000  
    
    autoSwitch: (event) ->
        
        toolKeys = 
            edit:    not event.ctrlKey and     event.altKey and not event.metaKey
            pan:         event.ctrlKey and not event.altKey and not event.metaKey
            pick:    not event.ctrlKey and not event.altKey and     event.metaKey
            pipette: not event.ctrlKey and     event.altKey and     event.metaKey
            loupe:       event.ctrlKey and     event.altKey and not event.metaKey
            
        shape = @kali.shapeTool()
        for s,k of toolKeys
            if k and shape != s
                @tools.clickTool s
                return s
        shape
    
    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    handleMouseDown: (event) =>
        
        @kali.focus()
        @tools.collapseTemp()
        
        shape = @kali.shapeTool()
        
        if @tools.getActive('shape')?.draw
            @draw ?= new Draw @kali
        else
            @draw?.del()
            delete @draw
        
        newShape = @autoSwitch event
        shape    = newShape
        
        eventPos = pos event 
        stagePos = @stage.stageForEvent eventPos
                    
        switch shape
            
            when 'pick'

                @stopEdit()
                @selection.stageStart drag, event
                    
            when 'edit'

                @selection.clear()
                @edit ?= new Edit @kali
                @edit.stageStart drag, event

            when 'pipette'
                
                item = @stage.itemAtPos eventPos
                if item? and item != @svg
                    
                    @tools.fill.color = item.style('fill')
                    @tools.fill.alpha = item.style('fill-opacity')
                    @tools.fill.update()
                    post.emit 'color', 'fill', 'color', @tools.fill.color
                    
                    @tools.stroke.color = item.style('stroke')
                    @tools.stroke.alpha = item.style('stroke-opacity')
                    @tools.stroke.update()
                    post.emit 'color', 'stroke', 'color', @tools.stroke.color
                    
                    @tools.width.setWidth item.style('stroke-width')
                
            when 'loupe' 
                
                @selection.loupe = @selection.addRect 'loupeRect'
                
            when 'pan' then
            else
                @selection.clear()
  
                if @drawing? and @draw?.handleDown event
                    if not @draw.continuePicking()
                        @endDrawing()
                    return
                    
                @drawing = @addShape shape, stagePos
                
                if @draw?
                    @draw.startDrawing @drawing, shape
                else
                    @trans.pos @drawing, stagePos

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDrag: (drag, event) =>

        shape = @autoSwitch event
        
        eventPos = pos event
        stagePos = @stage.stageForEvent eventPos
        
        if @draw?.handleDrag event
            return
        
        switch shape
            
            when 'pipette' then
                    
            when 'pan'   
                
                @stage.panBy drag.delta
                
            when 'loupe' 
                
                r = x:drag.startPos.x, y:drag.startPos.y, x2:drag.pos.x, y2:drag.pos.y                
                @selection.setRect @selection.loupe, r
                @stage.setCursor 'zoom-in'
                
            when 'pick'
                
                if @selection.rect?
                    @selection.moveRect eventPos, join:event.shiftKey
                else if not @resizer.empty()
                    @resizer.moveBy drag.delta
                    
            when 'edit'
                
                @edit ?= new Edit @kali
                @edit.stageDrag drag, event
                
            else
                if @drawing?
                    z  = @stage.zoom
                    p1 = @stage.stageForEvent drag.startPos
                    p2 = @stage.stageForEvent drag.pos
                    @trans.setRect @drawing, x:p1.x, y:p1.y, x2:p2.x, y2:p2.y

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onMove: (event) =>
        
        @draw?.handleMove event
        
    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onStop: (drag, event) =>
        
        eventPos = pos event
        stagePos = @stage.stageForEvent eventPos
        
        if @selection.rect?
            @selection.endRect eventPos
            return
            
        if @edit?
            @edit.stageStop drag, event
            return
            
        shape = @kali.shapeTool() 
            
        switch shape
            
            when 'edit' then return 
            when 'loupe' 
                
                @selection.loupe.remove()
                delete @selection.loupe
                @stage.loupe drag.startPos, drag.pos
                @stage.setCursor @tools.ctrlDown and 'zoom-out' or 'zoom-in'

        if @drawing

            if drag.startPos == drag.lastPos
                
                if @draw?.handlePick stagePos
                    return

                switch shape
                    when 'text' then
                    when 'ellipse'
                        @drawing.size 50, 100
                        @trans.center @drawing, stagePos
                    else
                        @drawing.size 100, 100
                        @trans.center @drawing, stagePos
                
            if not @draw? or @draw.handleStop event
                @endDrawing()

    # 00000000  000   000  0000000        0000000    00000000    0000000   000   000  
    # 000       0000  000  000   000      000   000  000   000  000   000  000 0 000  
    # 0000000   000 0 000  000   000      000   000  0000000    000000000  000000000  
    # 000       000  0000  000   000      000   000  000   000  000   000  000   000  
    # 00000000  000   000  0000000        0000000    000   000  000   000  00     00  

    handleEscape: ->
        
        if @draw?
            
            if @draw.handleEscape()
                @endDrawing()
                return true
            
        if @edit? 
            if @edit.dotsel.clear() then return true
            if @edit.clear()        then return true
            
        false    
    
    endDrawing: ->

        if @drawing
            
            @stopEdit()
            
            if @trans.width(@drawing) == 0 and @trans.height(@drawing) == 0

                @drawing.remove()
                
            else 
                if @stage.isEditableItem @drawing
                    @editItems [@drawing]
                else if @drawing.type == 'text'
                    @editTextItem @drawing
                else
                    @selection.setItems [@drawing]
                
            delete @drawing

        @draw?.del()
        delete @draw
            
    editItems: (items) ->

        @stopEdit()
        @edit = new Edit @kali
        @edit.setItems items
            
    stopEdit: ->
        
        @edit?.del()
        delete @edit    
            
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event, down) ->
        
        if @edit? and down
            switch combo
                when 'backspace', 'delete'
                    return @edit.delete()
                    
        'unhandled'
            
module.exports = Shapes

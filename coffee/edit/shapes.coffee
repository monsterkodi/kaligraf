###
 0000000  000   000   0000000   00000000   00000000   0000000
000       000   000  000   000  000   000  000       000     
0000000   000000000  000000000  00000000   0000000   0000000 
     000  000   000  000   000  000        000            000
0000000   000   000  000   000  000        00000000  0000000 
###

{ post, slash, drag, kpos } = require 'kxk'

{ uuid } = require '../utils'

Draw    = require './draw'
Edit    = require './edit'
Text    = require './text'
SnapBox = require './snapbox'

class Shapes

    log: -> #log.apply log, [].slice.call arguments, 0
    
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
            constrainKey: 'shiftKey'
            
        post.on 'stage', @onStage
        
    onStage: (action) =>

        if action == 'viewbox'
            if @kali.shapeTool() == 'text'
                @stage.setToolCursor 'text'

    do: (action) -> @stage.undo.do @, action
    done: -> @stage.undo.done @
            
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  
    
    state: -> 
        
        if @edit?
            edit: @edit.state()
        else
            {}
            
    restore: (state) ->
        
        if state.edit?
            @edit ?= new Edit @kali
            @edit.restore state.edit
    
    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape, stagePos) ->
        
        root = @stage.activeLayer()
        
        switch shape 
            
            when 'triangle'
                
                e = root.polygon '-0.50,0.50 0,-0.366 0.50,0.50'

            when 'triangle_square'
                
                e = root.polygon '0,0 1,1 0,1'
                
            when 'line', 'polyline', 'polygon'
                
                e = root[shape]()
                e.plot [[stagePos.x, stagePos.y], [stagePos.x, stagePos.y]]
                
            when 'bezier_smooth', 'bezier_quad', 'bezier_cube'

                arr = [ ['M', stagePos.x, stagePos.y] ]
                
                arr.push switch shape
                    when 'bezier_smooth' then ['S', stagePos.x, stagePos.y, stagePos.x, stagePos.y]
                    when 'bezier_quad'   then ['Q', stagePos.x, stagePos.y, stagePos.x, stagePos.y]
                    when 'bezier_cube'   then ['C', stagePos.x, stagePos.y, stagePos.x, stagePos.y, stagePos.x, stagePos.y]
                    
                a = new SVG.PathArray arr
                e = root.path()
                e.plot a

            when 'pie' 
                e = root.path 'M0,0 h1 a1,1 0 1,1 -1,-1,z'
                
            when 'arc'
                e = root.path 'M0,0 a1,1 0 0,0 -1,-1'
                
            when 'text'
                
                e = root.text 'X'
                e.leading 1.185
                e.font 'size',   @kali.tools.font.size
                e.font 'weight', @kali.tools.font.weight
                e.font 'style',  @kali.tools.font.style
                e.font 'family', @kali.tools.font.family
                e.font 'anchor', @kali.tools.anchor.anchor
                height = @trans.height e
                e.clear()
                e.data 'height', height
                
            when 'image'
                
                e = root.image slash.fileUrl slash.resolve '~/Desktop/kaligraf.png'
                stage = @kali.stage
                e.loaded (loader) ->
                    @size loader.width, loader.height
                    stage.selection.update()
                    stage.resizer.update()
                
            when 'snapbox'
                
                e = SnapBox.svgElem @kali, root
                                    
            else 
                if root[shape]?
                    e = root[shape]()
                else
                    log "Shapes.addShape -- no such shape? #{shape}"
                    return
              
        uuid e
              
        if shape not in ['snapbox']
            
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
                
    # 000000000  00000000  000   000  000000000  
    #    000     000        000 000      000     
    #    000     0000000     00000       000     
    #    000     000        000 000      000     
    #    000     00000000  000   000     000     
    
    editTextItem: (item) -> 

        @selection.clear()
        @text = new Text @kali, item
        
    clearText: ->

        @text?.del()
        delete @text
        
    #  0000000  000   000  000  000000000   0000000  000   000  
    # 000       000 0 000  000     000     000       000   000  
    # 0000000   000000000  000     000     000       000000000  
    #      000  000   000  000     000     000       000   000  
    # 0000000   00     00  000     000      0000000  000   000  
    
    autoSwitch: (event) ->
        
        # activeTool = @tools.getActive('shape')?.name
            
        toolKeys = 
            pick:    not event.shiftKey and not event.altKey and     event.ctrlKey
            edit:    not event.shiftKey and     event.altKey and not event.ctrlKey
            pan:     not event.shiftKey and     event.altKey and     event.ctrlKey
            pipette:     event.shiftKey and     event.altKey and     event.ctrlKey
            
        shape = @kali.shapeTool()
        for s,k of toolKeys
            if k and shape != s
                @tools.clickTool s
                return s
        shape

    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    onStart: (drag, event) => 

        delete drag.shift
        
        @clearText()
                            
        @handleMouseDown event
        
    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    handleMouseDown: (event) =>
        
        # @log 'Shapes.handleMouseDown'
        
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
        
        eventPos = kpos event 
        stagePos = @stage.stageForEvent eventPos
          
        if shape in ['loupe', 'pipette']
            @kali.tool(shape).onStageDown event
            return
        
        switch shape
            
            when 'pick'

                @stopEdit()
                if not event.ctrlKey
                    @log 'Shapes.handleMouseDown start selection rect', @stage.itemAtPos(eventPos)?.id()
                    @selection.stageStart drag, event
                    
            when 'edit'

                # log 'Shapes.handleMouseDown start edit', @stage.itemAtPos(eventPos)?.id()
                @selection.clear()
                @edit ?= new Edit @kali
                @edit.stageStart drag, event
                
            when 'pan' then
                    
            else
                
                if shape == 'text'
                    item = @stage.leafItemAtPos eventPos
                    if item?.type == 'text'
                        @editTextItem item
                        return
                
                @do() # done will be called in onStop
                @selection.clear()
  
                if @drawing? and @draw?.handleDown event
                    if not @draw.continuePicking()
                        @endDrawing()
                    return

                if shape in ['line', 'polyline'] and @kali.tool('width').width == 0
                    @kali.tool('width').setWidth 1
                    
                if @drawing = @addShape shape, stagePos
                    
                    if @draw?
                        @draw.startDrawing @drawing, shape
                    else
                        if shape == 'text' then stagePos.y -= @drawing.data('height')/2
                        @trans.pos @drawing, stagePos

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDrag: (drag, event) =>

        shape = @autoSwitch event
        
        eventPos = kpos event
        stagePos = @stage.stageForEvent eventPos
        
        # log 'onDrag', @draw?
        
        if @draw?.handleDrag event
            return
            
        if shape in ['loupe', 'pipette']
            @kali.tool(shape).onStageDrag drag, event
            return
        
        # log 'onDrag', shape
            
        switch shape
            
            when 'pan'   
                
                @stage.panBy drag.delta
                
                                
            when 'pick'
                
                if @selection.rect?
                    @selection.moveRect eventPos, join:event.shiftKey
                else if not @resizer.empty()
                    @resizer.moveBy drag.delta, event
                    
            when 'edit'
                
                @edit ?= new Edit @kali
                @edit.stageDrag drag, event
                
            else
                # log 'onDrag @drawing', @drawing?
                if @drawing?
                    
                    p1 = @stage.stageForEvent drag.startPos
                    p2 = @stage.stageForEvent drag.pos
                    rect = x:p1.x, y:p1.y, x2:p2.x, y2:p2.y
                    
                    if 'snapbox' == @drawing.data 'type'
                        SnapBox.setRect @drawing, rect
                    else
                        @trans.setRect @drawing, rect

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onMove: (event) =>
        # log 'shapes.onMove', @draw?
        @draw?.handleMove event
        
    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onStop: (drag, event) =>
        
        eventPos = kpos event
        stagePos = @stage.stageForEvent eventPos
        shape    = @kali.shapeTool() 
        
        if shape in ['loupe', 'pipette']
            @kali.tool(shape).onStageStop drag, event
            return
            
        @selection.emitSet()            
            
        if @selection.rect?
            @selection.endRect eventPos
            return
            
        @edit?.stageStop drag, event
        
        @kali.tool('snap').clear()
        
        if shape == 'edit' 
            return 
        
        if @drawing

            tooSmall = @trans.width(@drawing) == 0 and @trans.height(@drawing) == 0 #and @drawing.type != 'text'
            
            if drag.startPos == drag.lastPos or tooSmall
                
                if @draw?.handlePick stagePos
                    return

                @drawClickShape shape, stagePos
                
            if not @draw? or @draw.handleStop event
                @endDrawing()
                @done() # started in handleMouseDown

    drawClickShape: (shape, stagePos) ->
        
        switch shape
            when 'text' then
            when 'triangle' 
                @drawing.size 100, 50 * Math.sqrt 3
                @trans.center @drawing, stagePos
            when 'ellipse'
                @drawing.size 50, 100
                @trans.center @drawing, stagePos
            when 'snapbox' then true
            else
                @drawing.size 100, 100
                @trans.center @drawing, stagePos
                
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
            
            @draw?.handleEndDrawing()
            @stopEdit()
            
            if @trans.width(@drawing) == 0 and @trans.height(@drawing) == 0 and @drawing.type != 'text' and @drawing.type != 'svg'
                log 'remove @drawing', @drawing.type
                @drawing.remove()
                
            else
                if @drawing.type == 'text'
                    @editTextItem @drawing
                else if  @stage.isEditable @drawing
                    @editItems [@drawing]
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

    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    select: (select) ->

        switch select
            
            when 'none'
                
                if @edit? and not @edit.dotsel.empty()
                    @edit.dotsel.clear()
                else
                    @stopEdit()
                    @selection.clear()
                    
            when 'all'
                
                if @edit? and not @edit.empty()
                    @edit.dotsel.addAll()
                else if @edit? or @kali.shapeTool() == 'edit'
                    @editItems @stage.treeItems pickable:true
                else
                    # log 'select all : @selection.setItems pickableItems'
                    @selection.setItems @stage.pickableItems()
                   
            when 'groups'
                
                # log 'select groups'
                @selection.setItems @stage.pickableItems().filter (item) => item.type == 'g' 
                    
            when 'invert'
                
                if @edit? and not @edit.empty()
                    @edit.dotsel.invert()
                else if @edit? or @kali.shapeTool() == 'edit'
                    @editItems @stage.pickableItems().filter (item) => not @edit? or item not in @edit.items()
                else
                    @selection.setItems @stage.pickableItems().filter (item) => item not in @selection.items
                    
            when 'more'
                if @edit? and not @edit.empty()
                    @edit.dotsel.addMore()
                    
            when 'less'
                if @edit? and not @edit.empty()
                    @edit.dotsel.addLess()

            when 'next'
                if @edit? and not @edit.empty()
                    @edit.dotsel.addNext()
                    
            when 'prev'
                if @edit? and not @edit.empty()
                    @edit.dotsel.addPrev()
                    
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

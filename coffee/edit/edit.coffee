###
00000000  0000000    000  000000000
000       000   000  000     000
0000000   000   000  000     000
000       000   000  000     000
00000000  0000000    000     000
###

{ post, valid, empty, elem, last, kpos, drag, def, sh, _ } = require 'kxk'

{ rectOffset, normRect, rectsIntersect } = require '../utils'

Object  = require './object'
DotSel  = require './dotsel'
DotRes  = require './dotres'
Cursor  = require '../cursor'

class Edit

    constructor: (@kali, @passive) ->

        @name  = 'Edit'
        @stage = @kali.stage
        @trans = @kali.trans
        
        @element = elem 'div', id: 'edit'
        @element.classList.add 'passive' if @passive
        @element.addEventListener 'dblclick', @onDblClick
        @kali.insertAboveSelection @element

        @linesWhite = SVG(@element).size '100%', '100%'
        @linesWhite.addClass 'editLinesWhite'
        @linesWhite.viewbox @stage.svg.viewbox()
        
        @linesBlack = SVG(@element).size '100%', '100%'
        @linesBlack.addClass 'editLinesBlack'
        @linesBlack.viewbox @stage.svg.viewbox()
        
        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'editDots'
        @svg.viewbox @stage.svg.viewbox()

        @dotSize = @passive and 4 or 8
        @objects = []
        
        @dotsel = new DotSel @
        @dotres = new DotRes @dotsel
        
        @initDefs()
        
        post.on 'stage',    @onStage
        post.on 'convert',  @onConvert
        post.on 'gradient', @onGradient
        
    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        @clear()

        post.removeListener 'stage',    @onStage
        post.removeListener 'convert',  @onConvert
        post.removeListener 'gradient', @onGradient

        @element.removeEventListener 'dblclick', @onDblClick
        
        @dotsel?.del()
        @dotres?.del()
        
        @svg?.remove()
        @linesWhite?.remove()
        @linesBlack?.remove()
        @element?.remove()
        
        delete @svg
        delete @linesWhite
        delete @linesBlack
        delete @dotsel
        delete @dotres
        delete @element
        
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  

    do: (action) -> @stage.undo.do @, action
    done:        -> @stage.undo.done @
    
    state: ->
        
        state = 
            dotsel:  @dotsel.dots.map (dot) -> id:dot.ctrl.object.item.id(), index:dot.ctrl.index(), dot:dot.dot
            objects: @objects.map (obj) -> obj.item.id()
        state
        
    restore: (state) ->

        @dotsel.clear()
        
        @objects = []
        
        for id in state.objects
            item = SVG.get id
            @addItem item
        
        for {id, index, dot} in state.dotsel

            item   = SVG.get id
            object = @objectForItem item
            ctrl   = object.ctrlAt index
            if ctrl?
                dot = ctrl.dots[dot]
                @dotsel.addDot dot
            else
                log "no ctrl at index #{index}?"
            
    # 0000000    00000000  00000000   0000000  
    # 000   000  000       000       000       
    # 000   000  0000000   000000    0000000   
    # 000   000  000       000            000  
    # 0000000    00000000  000       0000000   
    
    initDefs: ->
        
        @defs = {}
        
        s  = @dotSize
        sh = @dotSize/2
        
        @defs['P'] = @svg.defs().polygon [[0,sh], [sh,0], [0,-sh], [-sh,0]]
        @defs['L'] = @svg.defs().rect s, s         
        @defs['M'] = @svg.defs().polygon [[-sh,-sh], [sh,-sh], [sh,sh]]
        @defs['C'] = @svg.defs().circle s
        @defs['Q'] = @svg.defs().circle s
        @defs['S'] = @svg.defs().circle s
        @defs['B'] = @svg.defs().circle 2*s
        @defs['B'].addClass 'snapbox'

        @defs['from']   = @svg.defs().rect s,s        
        @defs['to']     = @svg.defs().rect s,s        
        @defs['radius'] = @svg.defs().circle s        
        
        for k,def of @defs
            def.transform x: -def.cx(), y:-def.cy()
            def.addClass 'editDot'
            def.style cursor: Cursor.forTool 'edit hover'
        
        @updateDefs()
        
    updateDefs: ->

        for k,def of @defs
            def.transform scale:1/@stage.zoom
            
        dashArray = "#{2/@stage.zoom},#{6/@stage.zoom}"
        
        @linesWhite.style 
            'stroke-width':      1/@stage.zoom
            'stroke-dasharray':  dashArray
            'stroke-dashoffset': "#{2/@stage.zoom}"
        
        @linesBlack.style 
            'stroke-width':     1/@stage.zoom
            'stroke-dasharray': dashArray

    update: ->
        
        for object in @objects
            object.updatePos()
        
    #  0000000  000      00000000   0000000   00000000
    # 000       000      000       000   000  000   000
    # 000       000      0000000   000000000  0000000
    # 000       000      000       000   000  000   000
    #  0000000  0000000  00000000  000   000  000   000

    clear: ->

        editing = not @empty()
        @dotsel.clear()
        
        while valid @objects
            @delObject last @objects

        editing

    onStage: (action, box) => 
        
        if action == 'viewbox' 
            
            @svg.viewbox box
            @linesWhite.viewbox box
            @linesBlack.viewbox box
            @updateRect()
            @updateDefs()
            
    # 0000000    00000000  000      00000000  000000000  00000000  
    # 000   000  000       000      000          000     000       
    # 000   000  0000000   000      0000000      000     0000000   
    # 000   000  000       000      000          000     000       
    # 0000000    00000000  0000000  00000000     000     00000000  
    
    delete: ->
        
        if not @dotsel.empty()
            
            @do()
            for objectDot in @dotsel.objectDots()
                objectDot.object.delDots objectDot.dots
            @dotres.update()
            @done()
        
        else if not @empty()
            
            @do()
            for object in @objects
                if object.item.parent()?.removeElement?
                    object.item.remove()
                else
                    object.item.clear()
                    object.item.node.remove()
            @clear()
            @done()
    
    #  0000000   0000000   000   000  000   000  00000000  00000000   000000000  
    # 000       000   000  0000  000  000   000  000       000   000     000     
    # 000       000   000  000 0 000   000 000   0000000   0000000       000     
    # 000       000   000  000  0000     000     000       000   000     000     
    #  0000000   0000000   000   000      0      00000000  000   000     000     
    
    onConvert: (type) =>

        return if @dotsel.empty()
        
        @do()
        objectDots = @dotsel.objectDots()
        @dotsel.clear()
        newDots = []
        for objectDot in objectDots
            newDots = newDots.concat objectDot.object.convert objectDot.dots, type            
        @dotsel.addDots newDots
        @done()
    
    #  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  
    # 000        000   000  000   000  000   000  000  000       0000  000     000     
    # 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     
    # 000   000  000   000  000   000  000   000  000  000       000  0000     000     
    #  0000000   000   000  000   000  0000000    000  00000000  000   000     000     
    
    onGradient: (style, info) =>
        
        if style in ['fill', 'stroke']
            if info.item in @items()
                @objectForItem(info.item).updateGradi style, info
        
    # 000  000000000  00000000  00     00
    # 000     000     000       000   000
    # 000     000     0000000   000000000
    # 000     000     000       000 0 000
    # 000     000     00000000  000   000

    empty: -> empty @objects
    
    contains:      (item) -> @objectForItem item
    objectForItem: (item) -> @objects.find (o) -> o.item == item

    items: -> @objects.map (o) -> o.item
    
    setItems: (items) -> 
        
        @clear()
        @addItem item for item in items
    
    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    delItem: (item) ->

        if object = @objectForItem item
            @delObject object
        
    delObject: (object) ->

        if object in @objects
            
            for dot in object.dots()
                @dotsel.delDot dot
                
            object.del()
            
            _.pull @objects, object
            
    #  0000000   0000000    0000000        000  000000000  00000000  00     00  
    # 000   000  000   000  000   000      000     000     000       000   000  
    # 000000000  000   000  000   000      000     000     0000000   000000000  
    # 000   000  000   000  000   000      000     000     000       000 0 000  
    # 000   000  0000000    0000000        000     000     00000000  000   000  

    addItem: (item, o = join:true) ->

        if not o.join and @dotsel.empty()
            @clear()
        
        if object = @objectForItem item 
            return object
            
        if @stage.isEditable item
            object = new Object @, item
            @objects.push object 
            return object

    onDblClick: (event) =>
        
        if event.target.instance.ctrl
            
            ctrl = event.target.instance.ctrl
            dot  = event.target.instance.dot
            ctrl.object.straightenDot ctrl.index(), dot
            
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    stageStart: (drag, event) ->
        
        eventPos = kpos eventevent
                
        item = @stage.leafItemAtPos eventPos
        
        if @empty()
            if item?
                @addItem item, join:event.shiftKey
            else
                @startRect eventPos, join:event.shiftKey
        else
            @dotsel.startRect eventPos, join:event.shiftKey
    
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    stageDrag: (drag, event) ->
        
        eventPos = kpos event
        
        if @rect?
            @moveRect eventPos, join:event.shiftKey
        else 
            if @empty()
                @addItem @stage.leafItemAtPos eventPos, noType: 'text'
            else
                @dotsel.moveRect eventPos, join:event.shiftKey

    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    stageStop: (drag, event) ->
        
        if @rect? 
            @endRect kpos event
        else
            @dotsel.endRect kpos event
            
            if drag.startPos == drag.lastPos
                
                eventPos = kpos event
                
                if item = @stage.leafItemAtPos(eventPos)
                    object = @objectForItem item
                    if event.shiftKey and object
                        @delItem item
                    else if not object
                        @addItem item, join:event.shiftKey
                
    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveBy: (delta) ->
        
        if not @dotsel.empty()
            @dotsel.moveBy delta
        else
            @stage.moveItemsBy @items(), delta
            for object in @objects
                object.moveCtrlsBy delta
            
    # 00000000   00000000   0000000  000000000
    # 000   000  000       000          000
    # 0000000    0000000   000          000
    # 000   000  000       000          000
    # 000   000  00000000   0000000     000

    startRect: (p,o) ->

        @rect = @stage.offsetRect x:p.x, y:p.y, x2:p.x, y2:p.y
        @updateRect o

    moveRect: (p,o) ->

        vp = @stage.viewPos()
        @rect.x2 = p.x-vp.x
        @rect.y2 = p.y-vp.y
        @updateRect o

    endRect: (p) ->

        @rect.element.remove()
        delete @rect

    updateRect: (opt={}) ->

        return if not @rect?
        
        if not @rect.element
            @rect.element = @stage.selection.addRect()
            
        @stage.selection.setRect @rect.element, @rect
        
        @addInRect @rect, opt

    addInRect: (rect, opt) ->

        r = normRect rect
        
        vp = @stage.viewPos()
        r = x:r.x+vp.x, y:r.y+vp.y, x2:r.x2+vp.x, y2:r.y2+vp.y
        
        editableItems = @stage.editableItems()
        
        itemBoxes = editableItems.map (i) -> [i, i.rbox()]
  
        for itemBox in itemBoxes
            if rectsIntersect r, itemBox[1]
                @addItem itemBox[0]
            else if not opt.join
                @delItem itemBox[0]
            
module.exports = Edit

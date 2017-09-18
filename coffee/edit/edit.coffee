
# 00000000  0000000    000  000000000
# 000       000   000  000     000
# 0000000   000   000  000     000
# 000       000   000  000     000
# 00000000  0000000    000     000

{ post, drag, elem, empty, last, pos, log, _ } = require 'kxk'

{ rectOffset, normRect, rectsIntersect } = require '../utils'

Object = require './object'
DotSel = require './dotsel'
Cursor = require '../cursor'

class Edit

    constructor: (@kali, @passive) ->

        @stage   = @kali.stage
        @trans   = @kali.trans
        
        @element = elem 'div', id: 'edit'
        @element.classList.add 'passive' if @passive
        @kali.insertBelowTools @element

        @linesWhite = SVG(@element).size '100%', '100%'
        @linesWhite.addClass 'editLinesWhite'
        @linesWhite.viewbox @stage.svg.viewbox()
        
        @linesBlack = SVG(@element).size '100%', '100%'
        @linesBlack.addClass 'editLinesBlack'
        @linesBlack.viewbox @stage.svg.viewbox()
        
        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'editDots'
        @svg.viewbox @stage.svg.viewbox()

        @dotSize = @passive and 5 or 10
        @objects = []
        
        @dotsel  = new DotSel @

        @initDefs()
        
        post.on 'stage',   @onStage
        post.on 'convert', @onConvert
        
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
        @defs['M'] = @svg.defs().rect s, s 
        @defs['C'] = @svg.defs().circle s
        @defs['Q'] = @svg.defs().circle s
        @defs['S'] = @svg.defs().circle s
        
        for k,def of @defs
            def.transform x: -def.cx(), y:-def.cy()
            def.addClass 'editDot'
            def.style cursor: Cursor.forTool 'edit hover'
        
        @updateDefs()
        
    updateDefs: ->

        for k,def of @defs
            def.transform scale:1/@stage.zoom
            
        dashArray = "#{2/@stage.zoom},#{6/@stage.zoom}"
        
        @linesWhite.style 'stroke-width': 1/@stage.zoom
        @linesWhite.style 'stroke-dasharray': dashArray
        @linesWhite.style 'stroke-dashoffset': "#{2/@stage.zoom}"
        
        @linesBlack.style 'stroke-width': 1/@stage.zoom
        @linesBlack.style 'stroke-dasharray': dashArray
        
    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        @clear()

        post.removeListener 'stage', @onStage

        @svg.remove()
        @element.remove()

    #  0000000  000      00000000   0000000   00000000
    # 000       000      000       000   000  000   000
    # 000       000      0000000   000000000  0000000
    # 000       000      000       000   000  000   000
    #  0000000  0000000  00000000  000   000  000   000

    clear: ->

        editing = not @empty()
        @dotsel.clear()
        
        while @objects.length
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
            for objectDot in @dotsel.objectDots()
                objectDot.object.delDots objectDot.dots
            @dotsel.clear()
            return
        
        if not @empty()
            for object in @objects
                if object.item.parent()?.removeElement?
                    object.item.remove()
                else
                    object.item.clear()
                    object.item.node.remove()
        @clear()
    
    #  0000000   0000000   000   000  000   000  00000000  00000000   000000000  
    # 000       000   000  0000  000  000   000  000       000   000     000     
    # 000       000   000  000 0 000   000 000   0000000   0000000       000     
    # 000       000   000  000  0000     000     000       000   000     000     
    #  0000000   0000000   000   000      0      00000000  000   000     000     
    
    onConvert: (type) =>

        if not @dotsel.empty()
            for objectDot in @dotsel.objectDots()
                objectDot.object.convertDots objectDot.dots, type
        
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

        @delObject @objectForItem item
        
    delObject: (object) ->
        
        if object in @objects
            
            for dot in object.dots()
                @dotsel.del dot
                
            object.del()
            _.pull @objects, object

    #  0000000   0000000    0000000
    # 000   000  000   000  000   000
    # 000000000  000   000  000   000
    # 000   000  000   000  000   000
    # 000   000  0000000    0000000

    addItem: (item, o = join:true) ->

        if not o.join and @dotsel.empty() 
            @clear()
        
        if object = @objectForItem item 
            return object
            
        if @stage.isEditableItem item

            object = new Object @, item
            @objects.push object 
            
            return object

    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    stageStart: (drag, event) ->
        
        eventPos = pos event
        
        item = @stage.itemAtPos eventPos
        
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
        
        eventPos = pos event
        
        if @rect?
            @moveRect eventPos, join:event.shiftKey
        else 
            if @empty()
                @addItem @stage.itemAtPos eventPos
            else
                @dotsel.moveRect eventPos, join:event.shiftKey

    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    stageStop: (drag, event) ->
        
        if @rect? 
            @endRect pos event
        else
            @dotsel.endRect pos event
            
            if drag.startPos == drag.lastPos
                
                eventPos = pos event
                
                if item = @stage.itemAtPos eventPos
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
            @stage.moveItems @items(), delta
            for object in @objects
                object.moveCtrlsBy delta
            
    # 00000000   00000000   0000000  000000000
    # 000   000  000       000          000
    # 0000000    0000000   000          000
    # 000   000  000       000          000
    # 000   000  00000000   0000000     000

    startRect: (p,o) ->
        
        @rect = x:p.x, y:p.y, x2:p.x, y2:p.y
        @updateRect o

    moveRect: (p,o) ->

        @rect.x2 = p.x
        @rect.y2 = p.y
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
        
        for item in @kali.items()

            rb = item.rbox()
            if rectsIntersect r, rb
                
                @addItem item
                
            else if not opt.join
                
                @delItem item

module.exports = Edit

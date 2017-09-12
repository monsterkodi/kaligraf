
# 00000000  0000000    000  000000000
# 000       000   000  000     000
# 0000000   000   000  000     000
# 000       000   000  000     000
# 00000000  0000000    000     000

{ post, drag, elem, empty, last, pos, log, _ } = require 'kxk'

{ rectOffset, normRect, rectsIntersect } = require './utils'

Object = require './object'
DotSel = require './dotsel'

class Edit

    constructor: (@kali, @passive) ->

        @element = elem 'div', id: 'edit'
        @element.classList.add 'passive' if @passive
        @kali.insertBelowTools @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'editSVG'
        @svg.clear()

        @stage   = @kali.stage
        @trans   = @kali.trans

        @dotSize = @passive and 5 or 10
        @objects = []
        
        @dotsel  = new DotSel @

        post.on 'ctrl',  @onCtrl
        post.on 'stage', @onStage
        
    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        @clear()

        post.removeListener 'stage', @onStage
        post.removeListener 'ctrl',  @onCtrl

        @svg.remove()
        @element.remove()

    #  0000000  000      00000000   0000000   00000000
    # 000       000      000       000   000  000   000
    # 000       000      0000000   000000000  0000000
    # 000       000      000       000   000  000   000
    #  0000000  0000000  00000000  000   000  000   000

    clear: ->

        @dotsel.clear()
        
        while @objects.length
            @delObject last @objects

        @svg.clear()

    onStage: (action, box) => 
        
        for object in @objects
            object.updatePos()

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
    
    # 000  000000000  00000000  00     00
    # 000     000     000       000   000
    # 000     000     0000000   000000000
    # 000     000     000       000 0 000
    # 000     000     00000000  000   000

    empty: -> empty @objects
    
    contains:      (item) -> @objectForItem item
    objectForItem: (item) -> @objects.find (o) -> o.item == item

    items: -> @objects.map (o) -> o.item
    setItems: (items) -> @clear(); @addItem item for item in items
    
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

        if not o.join and @dotsel.empty() then @clear()
        
        if object = @objectForItem item 
            return object
            
        if @stage.isEditableItem item

            object = new Object @, item
            @objects.push object 
            return object

    #  0000000   000   000         0000000  000000000  00000000   000      
    # 000   000  0000  000        000          000     000   000  000      
    # 000   000  000 0 000        000          000     0000000    000      
    # 000   000  000  0000        000          000     000   000  000      
    #  0000000   000   000         0000000     000     000   000  0000000  

    onCtrl: (item, action, dot, index, p) =>

        if object = @objectForItem item
        
            object.editCtrl action, dot, index, p

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
                    if event.shiftKey and @objectForItem item
                        @delItem item
                    else
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

        if not @rect.element
            @rect.element = @stage.selection.addRect 'editRect'
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

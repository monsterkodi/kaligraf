
# 00000000  0000000    000  000000000
# 000       000   000  000     000
# 0000000   000   000  000     000
# 000       000   000  000     000
# 00000000  0000000    000     000

{ post, drag, elem, empty, last, pos, log, _ } = require 'kxk'

{ rectOffset, normRect, rectsIntersect } = require './utils'

Object = require './object'

class Edit

    constructor: (@kali, @passive) ->

        @element = elem 'div', id: 'edit'
        @element.classList.add 'passive' if @passive
        @kali.element.appendChild @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'editSVG'
        @svg.clear()

        @stage     = @kali.stage
        @trans     = @kali.trans
        @selection = @stage.selection

        @dotSize = @passive and 5 or 10
        @objects = []
        
        @selectedDots = []

        post.on 'ctrl',  @onCtrl
        post.on 'stage', @onStage

    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    selectDot: (dot, keep) ->
        
        if not keep
            for selected in @selectedDots
                selected.ctrl.setSelected selected.dot, false
            @selectedDots = []
                
        dot.ctrl.setSelected dot.dot, true
        if dot not in @selectedDots
            @selectedDots.push dot

    selectDotsInRect: (object, r, o) ->
        
        for dot in object.dots()
            rb = dot.rbox()
            if rectsIntersect r, rb
                @selectDot dot, o.join
            
    deselectDots: ->
        
        for dot in @selectedDots
            dot.ctrl.setSelected dot.dot, false
        @selectedDots = []
                
    deselectDot: (dot) ->
        
        if dot in @selectedDots
            dot.ctrl.setSelected dot.dot, false
            _.pull @selectedDots, dot
        
    moveDotsBy: (delta) ->
        
        for selected in @selectedDots
            ctrl   = selected.ctrl
            index  = ctrl.index()
            if index < 0
                log 'selected ctrl not in object?', index
                continue 
            object = ctrl.object
            oldPos = object.dotPos index, selected.dot
            if not oldPos.plus?
                log "dafuk? #{index} #{selected.dot}"
            newPos = oldPos.plus delta
            object.movePoint index, newPos, selected.dot
            object.plot()
        
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

        @deselectDots()
        
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
        
        if not empty @selectedDots
            for dot in @selectedDots
                dot.ctrl.object.delPoint dot.ctrl.index()
            @selectedDots = []
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

    empty: -> @objects.length <= 0
    
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
                @deselectDot dot
            object.del()
            _.pull @objects, object

    #  0000000   0000000    0000000
    # 000   000  000   000  000   000
    # 000000000  000   000  000   000
    # 000   000  000   000  000   000
    # 000   000  0000000    0000000

    addItem: (item, o = join:true) ->

        if not o.join and empty @selectedDots then @clear()
        
        if object = @objectForItem item 
            return object
            
        if _.isFunction item.array
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

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveBy: (delta) ->

        if not empty @selectedDots
            @moveDotsBy delta
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
        if not o.join and empty @selectedDots then @clear()
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
            @rect.element = @selection.addRect 'editRect'
        @selection.setRect @rect.element, @rect
        
        # if not empty @selectedDots
            # opt.join = true
        if not opt.join then @deselectDots()
        
        @addInRect @rect, opt

    addInRect: (rect, opt) ->

        r = normRect rect
        
        for item in @kali.items()

            rb = item.rbox()
            if rectsIntersect r, rb
                
                if object = @objectForItem item 
                    
                    log 'select item dots'
                    @selectDotsInRect object, r, join:true
                    
                else
                    @addItem item
                
            else if not opt.join
                
                @delItem item

module.exports = Edit


# 00000000  0000000    000  000000000
# 000       000   000  000     000
# 0000000   000   000  000     000
# 000       000   000  000     000
# 00000000  0000000    000     000

{ post, drag, elem, last, pos, log, _ } = require 'kxk'

{ rectOffset, normRect, rectsIntersect } = require './utils'

Object = require './object'

class Edit

    constructor: (@kali) ->

        @element = elem 'div', id: 'edit'
        @kali.element.appendChild @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'editSVG'
        @svg.clear()

        @stage     = @kali.stage
        @trans     = @kali.trans
        @selection = @stage.selection

        @dotSize = 10

        @objects = []

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

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    delItem: (item) ->

        @delObject @objectForItem item
        
    delObject: (object) ->
        
        if object in @objects
            object.del()
            _.pull @objects, object

    #  0000000   0000000    0000000
    # 000   000  000   000  000   000
    # 000000000  000   000  000   000
    # 000   000  000   000  000   000
    # 000   000  0000000    0000000

    addItem: (item) ->

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

    onCtrl: (item, action, type, index, p, point) =>

        if object = @objectForItem item
        
            object.editCtrl action, type, index, p, point

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveBy: (delta) ->

        for object in @objects
            @stage.moveItem object.item, delta
            object.moveBy delta
            
    # 00000000   00000000   0000000  000000000
    # 000   000  000       000          000
    # 0000000    0000000   000          000
    # 000   000  000       000          000
    # 000   000  00000000   0000000     000

    startRect: (p,o) ->

        @rect = x:p.x, y:p.y, x2:p.x, y2:p.y
        @pos = rectOffset @rect
        @updateRect o

    moveRect: (p,o) ->

        @rect.x2 = p.x
        @rect.y2 = p.y
        delete @pos
        @updateRect o

    endRect: (p) ->

        @rect.element.remove()
        delete @pos
        delete @rect

    updateRect: (opt={}) ->

        if not @rect.element
            @rect.element = @selection.addRect 'editRect'

        @selection.setRect @rect.element, @rect
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


# 00000000  0000000    000  000000000
# 000       000   000  000     000
# 0000000   000   000  000     000
# 000       000   000  000     000
# 00000000  0000000    000     000

{ post, drag, elem, last, pos, log, _ } = require 'kxk'

{ rectOffset, normRect, rectsIntersect } = require './utils'

Item = require './item'

class Edit

    constructor: (@kali) ->

        @element = elem 'div', id: 'edit'
        @kali.element.appendChild @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'editSVG'
        @svg.viewbox @kali.stage.svg.viewbox()
        @svg.clear()

        @stage     = @kali.stage
        @trans     = @kali.trans
        @selection = @stage.selection

        @dotSize = 10

        @items = []

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

        while @items.length
            @delItem last @items

        @svg.clear()

    onStage: (action, box) => if action == 'viewbox' then @svg.viewbox box

    # 0000000    00000000  000      00000000  000000000  00000000  
    # 000   000  000       000      000          000     000       
    # 000   000  0000000   000      0000000      000     0000000   
    # 000   000  000       000      000          000     000       
    # 0000000    00000000  0000000  00000000     000     00000000  
    
    delete: ->
        
        if not @empty()
            for item in @items
                if item.elem.parent()?.removeElement?
                    item.elem.remove()
                else
                    item.elem.clear()
                    item.elem.node.remove()
        @clear()
    
    # 000  000000000  00000000  00     00
    # 000     000     000       000   000
    # 000     000     0000000   000000000
    # 000     000     000       000 0 000
    # 000     000     00000000  000   000

    empty: -> @items.length <= 0
    
    contains:    (elem) -> @itemForElem elem
    itemForElem: (elem) -> @items.find (i) -> i.elem == elem

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    delItem: (item) ->

        if not item.elem?
            item = @itemForElem item
        
        if item in @items
            item.del()
            _.pull @items, item

    #  0000000   0000000    0000000
    # 000   000  000   000  000   000
    # 000000000  000   000  000   000
    # 000   000  000   000  000   000
    # 000   000  0000000    0000000

    addItem: (elem) ->

        if item = @itemForElem item then return item
        # log 'addItem', elem.id()
        item = new Item @, elem
        @items.push item 
        item

    #  0000000   000   000         0000000  000000000  00000000   000      
    # 000   000  0000  000        000          000     000   000  000      
    # 000   000  000 0 000        000          000     0000000    000      
    # 000   000  000  0000        000          000     000   000  000      
    #  0000000   000   000         0000000     000     000   000  0000000  

    onCtrl: (elem, action, type, index, p, point) =>

        if item = @itemForElem elem
        
            item.editCtrl action, type, index, p, point

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveBy: (delta) ->

        for item in @items
            @stage.moveElem item.elem, delta
            item.moveBy delta
            
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

        for child in @kali.items()

            rb = child.rbox()
            if rectsIntersect r, rb
                @addItem child
            else if not opt.join
                @delItem child

module.exports = Edit

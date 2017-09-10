
# 0000000     0000000   000000000   0000000  00000000  000    
# 000   000  000   000     000     000       000       000    
# 000   000  000   000     000     0000000   0000000   000    
# 000   000  000   000     000          000  000       000    
# 0000000     0000000      000     0000000   00000000  0000000

{ empty, log, _ } = require 'kxk'

{ rectsIntersect, normRect } = require './utils'

class DotSel

    constructor: (@edit) ->

        @stage = @edit.stage
        @dots = []

    #  0000000   0000000          000  0000000     0000000   000000000   0000000  
    # 000   000  000   000        000  000   000  000   000     000     000       
    # 000   000  0000000          000  000   000  000   000     000     0000000   
    # 000   000  000   000  000   000  000   000  000   000     000          000  
    #  0000000   0000000     0000000   0000000     0000000      000     0000000   
    
    objectDots: ->
        
        objectDots = []
        for i in [0...@edit.objects.length]
            object = @edit.objects[i]
            dots = object.dots().filter (dot) => dot in @dots
            if not empty dots
                objectDots.push 
                    object: object
                    dots:   dots
        objectDots
        
    #  0000000  000      00000000   0000000   00000000   
    # 000       000      000       000   000  000   000  
    # 000       000      0000000   000000000  0000000    
    # 000       000      000       000   000  000   000  
    #  0000000  0000000  00000000  000   000  000   000  
    
    clear: ->
        
        for dot in @dots
            dot.ctrl?.setSelected dot.dot, false
            
        @dots = []

    empty: -> empty @dots
            
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    add: (dot, keep=true) ->
        
        @clear() if not keep
        
        dot.ctrl.setSelected dot.dot, true
        
        if dot not in @dots then @dots.push dot

    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    del: (dot) ->
        
        if dot in @dots
            dot.ctrl.setSelected dot.dot, false
            _.pull @dots, dot
        
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveBy: (delta) ->
        
        for dot in @dots
            ctrl   = dot.ctrl
            index  = ctrl.index()
            object = ctrl.object
            oldPos = object.dotPos index, dot.dot
            newPos = oldPos.plus delta
            object.movePoint index, newPos, dot.dot
        object.plot()

    # 00000000   00000000   0000000  000000000
    # 000   000  000       000          000
    # 0000000    0000000   000          000
    # 000   000  000       000          000
    # 000   000  00000000   0000000     000

    startRect: (p,o) ->
        
        @rect = x:p.x, y:p.y, x2:p.x, y2:p.y
        @updateRect o

    moveRect: (p,o) ->

        if not @rect? then return
        
        @rect.x2 = p.x
        @rect.y2 = p.y
        @updateRect o

    endRect: (p) ->

        @rect?.element.remove()
        delete @rect

    updateRect: (o) ->

        if not @rect.element
            @rect.element = @stage.selection.addRect 'editRect'
        @stage.selection.setRect @rect.element, @rect
        
        @addInRect normRect(@rect), o

    addInRect: (r, o) ->

        for object in @edit.objects
            for dot in object.dots()
                if rectsIntersect r, dot.rbox()
                    @add dot, true
                else if not o.join
                    @del dot
    addAll: ->
        
        for object in @edit.objects
            for dot in object.dots()
                @add dot, true
                
    invert: ->
        
        for object in @edit.objects
            for dot in object.dots()
                if dot.hasClass 'selected'
                    @del dot
                else
                    @add dot, true
                    
module.exports = DotSel

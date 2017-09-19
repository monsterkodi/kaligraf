
# 0000000     0000000   000000000   0000000  00000000  000    
# 000   000  000   000     000     000       000       000    
# 000   000  000   000     000     0000000   0000000   000    
# 000   000  000   000     000          000  000       000    
# 0000000     0000000      000     0000000   00000000  0000000

{ empty, drag, post, log, _ } = require 'kxk'

{ rectsIntersect, normRect } = require '../utils'

class DotSel

    constructor: (@edit) ->

        @kali  = @edit.kali
        @stage = @kali.stage
        @dots  = []
        
        @drag = new drag
            target:  @edit.element
            onStart: @onStart
            onMove:  @onDrag
            
        post.on 'stage', @onStage
        
    onStage: (action) => if action == 'viewbox' then @updateRect()

    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    onStart: (drag, event) =>
        
        if dot = event.target.instance

            if @kali.shapeTool() != 'edit'
                post.emit 'tool', 'click', 'edit'
            
            if event.shiftKey and dot.ctrl.isSelected dot.dot
                @del dot
            else
                keep = event.shiftKey or dot.ctrl.isSelected dot.dot
                @add dot, keep
                        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDrag: (drag, event) =>
        
        if not @empty()
            @moveBy drag.delta.times(1/@kali.stage.zoom), event

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveBy: (delta, event) ->
        # log 'dotsel.moveBy', delta
        for objectDot in @objectDots()
        
            objectDot.object.moveDotsBy objectDot.dots, delta, event
            
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
        
        dotSelected = false
        for dot in @dots
            if dot.ctrl?.isSelected dot.dot then dotSelected = true
            dot.ctrl?.setSelected dot.dot, false
            
        @dots = []
        dotSelected

    empty: -> empty @dots

    invert: ->
        
        for object in @edit.objects
            for dot in object.dots()
                if dot.hasClass 'selected'
                    @del dot
                else
                    @add dot, true
    
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    add: (dot, keep=true) ->
        
        @clear() if not keep
        
        dot.ctrl.setSelected dot.dot, true
        
        if dot not in @dots then @dots.push dot

    addInRect: (r, o) ->

        for object in @edit.objects
            for dot in object.dots()
                if rectsIntersect r, dot.rbox()
                    @add dot, true
                else if not o?.join
                    @del dot
    addAll: ->
        
        for object in @edit.objects
            for dot in object.dots()
                @add dot, true

    addDots: (dots) ->
        
        for dot in dots
            @add dot, true
                
    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    del: (dot) ->
        
        if dot in @dots
            dot.ctrl.setSelected dot.dot, false
            _.pull @dots, dot
        
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

        return if not @rect?
        
        if not @rect.element
            @rect.element = @stage.selection.addRect()
        @stage.selection.setRect @rect.element, @rect
        
        @addInRect normRect(@rect), o
                                    
module.exports = DotSel

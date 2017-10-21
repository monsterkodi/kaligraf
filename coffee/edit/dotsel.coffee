
# 0000000     0000000   000000000   0000000  00000000  000    
# 000   000  000   000     000     000       000       000    
# 000   000  000   000     000     0000000   0000000   000    
# 000   000  000   000     000          000  000       000    
# 0000000     0000000      000     0000000   00000000  0000000

{ empty, drag, post, pos, log, _ } = require 'kxk'

{ rectsIntersect, normRect, bboxForItems, itemIDs } = require '../utils'

class DotSel

    constructor: (@edit) ->

        @name  = 'DotSel' 
        @kali  = @edit.kali
        @stage = @kali.stage
        @trans = @kali.trans
        @dots  = []

        @drag = new drag
            target:  @edit.element
            onStart: @onStart
            onMove:  @onDrag
            onStop:  @onStop
            constrainKey: 'shiftKey'

        post.on 'stage', @onStage
        
    del: ->

        @drag?.deactivate()
        delete @drag
        
        post.removeListener 'stage', @onStage
        
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
                @delDot dot
            else
                keep = event.shiftKey or dot.ctrl.isSelected dot.dot
                @addDot dot, keep:keep

    onStop: (drag, event) =>
    
        delete @shift
                
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

        @stage.do 'move-dots', itemIDs, @edit.objects.map (o) -> o.item
        
        for objectDot in @objectDots()
            objectDot.object.moveDotsBy objectDot.dots, delta, event
            
        for gradiDot in @gradiDots()
            gradiDot.gradi.moveDotsBy gradiDot.dots, delta
            
        post.emit 'dotsel', 'move', dotsel:@, delta:delta, event:event
        
        @stage.done()

    update: ->

        for objectDot in @objectDots()
            objectDot.object.updateDots objectDot.dots
            
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

    gradiDots: ->
        
        gradiDots = []
        for i in [0...@edit.objects.length]
            object = @edit.objects[i]
            continue if not object.gradi?
            for k,gradi of object.gradi
                dots = _.values(gradi.dots).filter (dot) => dot in @dots
                if not empty dots
                    gradiDots.push 
                        gradi: gradi
                        dots:  dots
        gradiDots
        
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
        
        post.emit 'dotsel', 'clear' if dotSelected
        
        dotSelected

    empty:   -> empty @dots
    numDots: -> @dots.length
    bbox:    -> bboxForItems @dots

    invert: ->
        
        for object in @edit.objects
            for dot in object.dots()
                if dot.hasClass 'selected'
                    @delDot dot
                else
                    @addDot dot, keep:true
    
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    addDot: (dot, opt = { keep:true, emit:true }) ->
        
        @clear() if not opt?.keep
        
        dot.ctrl.setSelected dot.dot, true
        
        if dot not in @dots 
            
            @dots.push dot
            
            if opt?.emit
                post.emit 'dotsel', 'add', @dots, dot

    addInRect: (r, o) ->

        for object in @edit.objects
            for dot in object.dots()
                if rectsIntersect r, dot.rbox()
                    @addDot dot, keep:true
                else if not o?.join
                    @delDot dot
                    
            for k,gradi of object.gradi ? {}
                for k,dot of gradi.dots 
                    if rectsIntersect r, dot.rbox()
                        @addDot dot, keep:true
                    else if not o?.join
                        @delDot dot
                    
    addAll: ->
        
        for object in @edit.objects
            for dot in object.dots()
                @addDot dot, keep:true, emit:false
            for k,gradi of object.gradi ? {}
                for k,dot of gradi.dots 
                    @addDot dot, keep:true, emit:false
                
        post.emit 'dotsel', 'set', @dots

    addDots: (dots) ->
        
        for dot in dots
            @addDot dot, keep:true
                
    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    delDot: (dot) ->
        
        if dot in @dots
            dot.ctrl.setSelected dot.dot, false
            _.pull @dots, dot
            
            post.emit 'dotsel', 'del', @dots, dot
        
    # 00000000   00000000   0000000  000000000
    # 000   000  000       000          000
    # 0000000    0000000   000          000
    # 000   000  000       000          000
    # 000   000  00000000   0000000     000

    startRect: (p,o) ->
        
        post.emit 'dotsel', 'startRect'
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
        post.emit 'dotsel', 'endRect', @dots

    updateRect: (o) ->

        return if not @rect?
        
        if not @rect.element
            @rect.element = @stage.selection.addRect()
        @stage.selection.setRect @rect.element, @rect
        
        @addInRect normRect(@rect), o
        
    #  0000000   000      000   0000000   000   000  
    # 000   000  000      000  000        0000  000  
    # 000000000  000      000  000  0000  000 0 000  
    # 000   000  000      000  000   000  000  0000  
    # 000   000  0000000  000   0000000   000   000  
    
    align: (side) ->
        
        return if @numDots() < 2
        
        @stage.do 'align'
        
        sum = 0
        min = Number.MAX_SAFE_INTEGER
        max = Number.MIN_SAFE_INTEGER
        
        for dot in @dots
            switch side
                when 'left'   then min = Math.min min, dot.cx()
                when 'top'    then min = Math.min min, dot.cy()
                when 'right'  then max = Math.max max, dot.cx()
                when 'bot'    then max = Math.max max, dot.cy()
                when 'center' then sum += dot.cx()
                when 'mid'    then sum += dot.cy()
                    
        avg = sum / @numDots()
        
        for dot in @dots
            switch side
                when 'left'   then dot.cx min
                when 'top'    then dot.cy min
                when 'right'  then dot.cx max
                when 'bot'    then dot.cy max
                when 'center' then dot.cx avg
                when 'mid'    then dot.cy avg
        
        @update()
        @edit.dotres.update()
        @stage.selection.update()
        @stage.resizer.update()
        
        @stage.done()
         
    #  0000000  00000000    0000000    0000000  00000000  
    # 000       000   000  000   000  000       000       
    # 0000000   00000000   000000000  000       0000000   
    #      000  000        000   000  000       000       
    # 0000000   000        000   000   0000000  00000000  
    
    space: (direction) ->
        
        return if @numDots() < 3
        
        @stage.do "space-#{direction}"
        switch direction
            when 'horizontal' then @dots.sort (a,b) => @trans.center(a).x - @trans.center(b).x
            when 'vertical'   then @dots.sort (a,b) => @trans.center(a).y - @trans.center(b).y
              
        sum = 0
        for i in [1...@dots.length]
            a = @dots[i-1]
            b = @dots[i]
            ra = @trans.getRect a
            rb = @trans.getRect b
            switch direction
                when 'horizontal' then sum += rb.x - ra.x2
                when 'vertical'   then sum += rb.y - ra.y2
                
        avg = sum/(@dots.length-1)
        
        for i in [1...@dots.length]
            a = @dots[i-1]
            b = @dots[i]
            ra = @trans.getRect a
            newPos = @trans.pos b
            switch direction
                when 'horizontal' then newPos.x = ra.x2 + avg
                when 'vertical'   then newPos.y = ra.y2 + avg

            b.cx newPos.x
            b.cy newPos.y
            
        @update()
        @edit.dotres.update()
        @stage.selection.update()
        @stage.resizer.update()
        
        @stage.done()
        
module.exports = DotSel

###
0000000     0000000   000000000   0000000  00000000  000    
000   000  000   000     000     000       000       000    
000   000  000   000     000     0000000   0000000   000    
000   000  000   000     000          000  000       000    
0000000     0000000      000     0000000   00000000  0000000
###

{ empty, drag, post, first, pos, log, _ } = require 'kxk'

{ rectsIntersect, normRect, bboxForItems, itemIDs, boxCenter } = require '../utils'

SnapBox = require './snapbox'

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

        delete @snapLine
            
        if dot = event.target.instance

            parent = dot.ctrl.object.item.parent()
            if parent?.type == 'g' and 'snapbox' == parent.data 'type'
                log 'dotsel.onStart', parent.type, parent.data 'type'
                @snapLine = SnapBox.onStartDragDot @kali, parent, dot, event
                return
            
            if @kali.shapeTool() != 'edit'
                post.emit 'tool', 'click', 'edit'
            
            if event.shiftKey and dot.ctrl.isSelected dot.dot
                @delDot dot
            else
                keep = event.shiftKey or dot.ctrl.isSelected dot.dot
                @addDot dot, keep:keep

    onStop: (drag, event) =>
    
        @snapLine?.onDragStop drag, event           
        delete @snapLine
        delete @shift
        @kali.tool('snap').clear()
                
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDrag: (drag, event) =>

        if @snapLine
            @snapLine.onDrag drag, event
            return
        
        if not @empty()
            
            @moveBy drag.delta.times(1/@stage.zoom), event

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveBy: (delta, event) ->

        @stage.do 'move-dots', itemIDs, @edit.objects.map (o) -> o.item
        
        # if not event?.metaKey
        if not event?.ctrlKey
            delta = @kali.tool('snap').delta delta, dots:@dots
        else
            @kali.tool('snap').clear()
        
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
    dotBox:  -> 
        
        minx = Number.MAX_SAFE_INTEGER
        miny = Number.MAX_SAFE_INTEGER
        maxx = Number.MIN_SAFE_INTEGER
        maxy = Number.MIN_SAFE_INTEGER
        
        for dot in @dots
            minx = Math.min dot.cx(), minx
            maxx = Math.max dot.cx(), maxx

            miny = Math.min dot.cy(), miny
            maxy = Math.max dot.cy(), maxy
            
        x:  minx
        y:  miny
        x2: maxx
        y2: maxy
        cx: minx+(maxx-minx)/2
        cy: miny+(maxy-miny)/2
        w:  maxx-minx
        h:  maxy-miny
        width:maxx-minx
        height:maxy-miny
        
    center: ->
        
        center = pos 0,0
        unique = @uniqueDotPositions()
        for dotPos in unique
            center.add dotPos
        center.scale 1/unique.length

    uniqueDotPositions: ->
        
        dotPositions = []
        for dot in @dots
            dotPos = pos dot.cx(), dot.cy()
            use = true
            for usedPos in dotPositions
                if dotPos.isClose usedPos, 0.01
                    use = false
                    break
            if use then dotPositions.push dotPos
        dotPositions
        
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
    
    setDots: (dots) ->
        
        @clear()
        
        @dots = _.clone dots
        for dot in @dots
            dot.ctrl.setSelected dot.dot, true
    
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

    addMore: ->
        
        oldDots = @dots.filter (dot) -> dot.dot == 'point'
        @setDots oldDots
        
        for object in @edit.objects
            for dot in object.dots()
                continue if dot.dot != 'point'
                if dot not in oldDots
                    if (object.prevDot(dot) in oldDots) or (object.nextDot(dot) in oldDots)
                        @addDot dot, keep:true, emit:false

        post.emit 'dotsel', 'set', @dots

    addLess: ->
        
        oldDots = @dots.filter (dot) -> dot.dot == 'point'
        @setDots oldDots
        
        for object in @edit.objects
            for dot in object.dots()
                continue if dot.dot != 'point'                               
                if dot in oldDots
                    if (object.prevDot(dot) not in oldDots) or (object.nextDot(dot) not in oldDots)
                        @delDot dot
                
        post.emit 'dotsel', 'set', @dots

    addNext: ->
        
        oldDots = @dots.filter (dot) -> dot.dot == 'point'
        @setDots oldDots
        
        for object in @edit.objects
            for dot in object.dots()
                continue if dot.dot != 'point' 
                if dot in oldDots 
                    if object.prevDot(dot) not in oldDots
                        @delDot dot
                else
                    if object.prevDot(dot) in oldDots
                        @addDot dot, keep:true, emit:false
                
        post.emit 'dotsel', 'set', @dots

    addPrev: ->
        
        oldDots = @dots.filter (dot) -> dot.dot == 'point'
        @setDots oldDots
        
        for object in @edit.objects
            for dot in object.dots()
                continue if dot.dot != 'point'
                if dot in oldDots 
                    if object.nextDot(dot) not in oldDots
                        @delDot dot
                else
                    if object.nextDot(dot) in oldDots
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
        vp = @stage.viewPos()
        @rect = x:p.x-vp.x, y:p.y-vp.y, x2:p.x-vp.x, y2:p.y-vp.y
        @updateRect o

    moveRect: (p,o) ->

        if not @rect? then return
        vp = @stage.viewPos()
        @rect.x2 = p.x-vp.x
        @rect.y2 = p.y-vp.y
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
        
        vp = @stage.viewPos()
        r = x:@rect.x+vp.x, y:@rect.y+vp.y, x2:@rect.x2+vp.x, y2:@rect.y2+vp.y
        @addInRect normRect(r), o
        
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
        
    # 00000000    0000000   0000000    000   0000000   000      
    # 000   000  000   000  000   000  000  000   000  000      
    # 0000000    000000000  000   000  000  000000000  000      
    # 000   000  000   000  000   000  000  000   000  000      
    # 000   000  000   000  0000000    000  000   000  0000000  
    
    spaceRadial: ->
        
        return if @numDots() < 3

        @stage.do "space-radial"
        
        center = pos 0,0
        centerDots = []
        for i in [0...@dots.length]
            if @dots[i].ctrl.index() == 0 and @dots[i].ctrl.object.isClosed()
                log 'closed'
                continue 
            dotCenter = pos @dots[i].cx(), @dots[i].cy()
            center.add dotCenter
            centerDots.push center:dotCenter, dot:@dots[i]
            
        center.scale 1/centerDots.length
                
        for centerDot in centerDots
            angle = center.to(centerDot.center).rotation(pos 1,0)
            angle += 360 if angle < 0
            centerDot.angle = angle

        centerDots.sort (a,b) -> a.angle - b.angle 
          
        angle = first(centerDots).angle
        aincr = 360/centerDots.length
        
        for centerDot in centerDots
            length = center.to(centerDot.center).length()
            direction = pos(1,0).rotate angle
            newPos = center.plus direction.scale length
            centerDot.dot.cx newPos.x
            centerDot.dot.cy newPos.y
            angle += aincr
            
        @update()
        @edit.dotres.update()
        @stage.selection.update()
        @stage.resizer.update()
        
        @stage.done()
        
    # 00000000    0000000   0000000    000  000   000   0000000  
    # 000   000  000   000  000   000  000  000   000  000       
    # 0000000    000000000  000   000  000  000   000  0000000   
    # 000   000  000   000  000   000  000  000   000       000  
    # 000   000  000   000  0000000    000   0000000   0000000   
    
    averageRadius: ->
        
        return if @numDots() < 3
        
        @stage.do "average-radius"
        
        center = pos 0,0
        dotCenters = []
        for i in [0...@dots.length]
        
            dotCenter = pos @dots[i].cx(), @dots[i].cy()
            center.add dotCenter
            dotCenters.push dotCenter
            
        center.scale 1/@dots.length
        
        radius = 0
        for i in [0...@dots.length]
            radius += center.to(dotCenters[i]).length()
            
        radius /= @dots.length
        
        for i in [0...@dots.length]
            newPos = center.plus center.to(dotCenters[i]).normal().scale radius
            @dots[i].cx newPos.x
            @dots[i].cy newPos.y
            
        @update()
        @edit.dotres.update()
        @stage.selection.update()
        @stage.resizer.update()
        
        @stage.done()
        
module.exports = DotSel

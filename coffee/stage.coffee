
#  0000000  000000000   0000000    0000000   00000000  
# 000          000     000   000  000        000       
# 0000000      000     000000000  000  0000  0000000   
#      000     000     000   000  000   000  000       
# 0000000      000     000   000   0000000   00000000  

{ resolve, elem, post, drag, last, pos, fs, log, _ } = require 'kxk'
{ growViewBox, normRect, boxForItems } = require './utils'
{ clipboard } = require 'electron' 

SVG       = require 'svg.js'
clr       = require 'svg.colorat.js'
Selection = require './selection'
Resizer   = require './resizer'

class Stage

    constructor: (@kali) ->

        @element = elem 'div', id: 'stage'
        @kali.element.appendChild @element
        @svg = SVG(@element).size '100%', '100%' 
        @svg.addClass 'stageSVG'
        @svg.clear()
        
        @kali.stage = @
        
        @selection = new Selection @kali
        @resizer   = new Resizer   @kali
        
        @drag = new drag
            target:  @element
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop

        window.area.on 'resized', @onResize

        @resetView()

    # 000  000000000  00000000  00     00  
    # 000     000     000       000   000  
    # 000     000     0000000   000000000  
    # 000     000     000       000 0 000  
    # 000     000     00000000  000   000  
    
    itemAtPos: (p) ->
        
        e = document.elementsFromPoint p.x, p.y
        for i in e
            if i.instance? and i != @svg and i.instance in @svg.children()
                return i.instance
        
    #  0000000  000   000   0000000   
    # 000       000   000  000        
    # 0000000    000 000   000  0000  
    #      000     000     000   000  
    # 0000000       0       0000000   
    
    setSVG: (svg) ->
        
        @clear()
        @addSVG svg, select:false
        @resetView()
        
    addSVG: (svg, opt) ->
        
        e = elem 'div'
        e.innerHTML = svg
        
        if e.firstChild.tagName == 'svg'

            svg = SVG.adopt e.firstChild
            if svg? and svg.children().length
                
                @selection.clear()
                
                for child in svg.children()
                    @svg.svg child.svg()
                    added = last @svg.children() 
                    if added.type != 'defs' and opt?.select != false
                        @selection.add last @svg.children() 

    getSVG: (items, bb) ->
        
        selected = _.clone @selection.items
        @selection.clear()
        
        svgStr = '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" '
        svgStr += "viewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        for item in items
            svgStr += item.svg()
        svgStr += '</svg>'
        
        for item in selected
            @selection.add item
        
        svgStr
                    
    #  0000000   0000000   00000000   000   000  
    # 000       000   000  000   000   000 000   
    # 000       000   000  00000000     00000    
    # 000       000   000  000           000     
    #  0000000   0000000   000           000     
    
    copy: -> 
        
        selected = _.clone @selection.items
        items = @selection.empty() and @svg.children() or selected
        return if items.length <= 0
        @selection.clear()
        
        bb = boxForItems items, @viewPos()
        growViewBox bb
        
        svg = @getSVG items, bb
        clipboard.writeText svg
        log svg
        
        for item in selected
            @selection.add item        

    paste: -> 
        
        delete @selection.pos
        @addSVG clipboard.readText()

    cut: -> 
        
        if not @selection.empty()
            @copy()
            @selection.delete()
    
    clear: -> 
        
        @selection.clear()
        @svg.clear()
        @resetView()

    #  0000000   0000000   000   000  00000000  
    # 000       000   000  000   000  000       
    # 0000000   000000000   000 000   0000000   
    #      000  000   000     000     000       
    # 0000000   000   000      0      00000000  
    
    save: -> 
        
        svg = @getSVG @svg.children(), x:0, y:0, width:@viewSize().width, height:@viewSize().height
        fs.writeFileSync resolve('~/Desktop/kaligraf.svg'), svg
        
    load: ->
        
        svg = fs.readFileSync resolve('~/Desktop/kaligraf.svg'), encoding: 'utf8'
        @setSVG svg
                    
    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape, stagePos, attr, style) ->
        
        switch shape 
            when 'triangle'
                e = @svg.polygon '-50,50 0,-50 50,50'
            when 'line', 'polyline', 'polygon'
                e = @svg[shape]()
                e.plot [[stagePos.x, stagePos.y], [stagePos.x, stagePos.y]]
            else
                e = @svg[shape]()
            
        e.style
            stroke:           @kali.tools.stroke.color
            'stroke-opacity': @kali.tools.stroke.alpha
            'stroke-width':   @kali.tools.width.width
            
        if shape not in ['polyline', 'line']
            e.style
                fill:           @kali.tools.fill.color
                'fill-opacity': @kali.tools.fill.alpha
        else
            e.style 
                fill:           'none'
                'fill-opacity': 0.0
            
        e.attr  attr  if attr?
        e.style style if style?
        e
        
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    onDragStart: (drag, event) => @handleMouseDown event
        
    handleMouseDown: (event) ->

        @kali.focus()
        @kali.tools.collapseTemp()
        
        shape = @kali.shapeTool()
        
        for s,k of {pick:event.metaKey, pan:event.altKey, loupe:event.ctrlKey}
            if k and shape != s
                @kali.tools[s].onClick()
                shape = s
        
        eventPos = @eventPos event 
        stagePos = @stagePos event
                
        switch shape
            
            when 'pick'

                e = @itemAtPos eventPos
                
                if not e?
                    # log 'ADOPT!!!', event.target.id
                    e = SVG.adopt event.target
                    
                if e == @svg
                    if not event.shiftKey
                        @selection.clear()
                    @selection.start @eventPos(event), join:event.shiftKey
                else
                    if not @selection.contains e
                        if not event.shiftKey
                            @selection.clear()
                        @selection.pos = @eventPos(event)
                        @selection.add e
                    else
                        if event.shiftKey
                            @selection.del e
                            
            when 'loupe' 
                
                @selection.loupe = @selection.addRect 'loupe'
                
            when 'pan' then
            else
                @selection.clear()
                
                if @drawing? and shape in ['line', 'polygon', 'polyline']
                    switch shape
                        when 'polygon', 'polyline' 
                            @addPolyPoint stagePos
                        when 'line'                
                            @setLinePoint stagePos
                            delete @drawing
                    return
                        
                @drawing = @addShape shape, stagePos 
                @drawing.cx stagePos.x
                @drawing.cy stagePos.y

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onDragMove: (drag, event) =>

        shape = @kali.shapeTool()
        
        stagePos = @stagePos event
        
        switch shape
            
            when 'pan'   
                
                @panBy drag.delta
                
            when 'loupe' 
                
                r = x:drag.startPos.x, y:drag.startPos.y, x2:drag.pos.x, y2:drag.pos.y                
                @selection.setRect @selection.loupe, r
                
            when 'pick'
                
                if @selection.rect?
                    @selection.move @eventPos(event), join:event.shiftKey

            when 'line' 
                
                @setLinePoint stagePos
                                
            when 'polygon', 'polyline'
                
                @addPolyPoint stagePos
                
            else
                
                @drawing.width  drag.deltaSum.x
                @drawing.height drag.deltaSum.y
                
                switch shape
                    when 'ellipse', 'circle'
                        @drawing.cx drag.startPos.x - @viewPos().x + @drawing.width()/2
                        @drawing.cy drag.startPos.y - @viewPos().y + @drawing.height()/2

    setLinePoint: (p) ->
        
        arr = @drawing.array().valueOf()
        last(arr)[0] = p.x
        last(arr)[1] = p.y
        @drawing.plot arr
        
    addPolyPoint: (p) ->
        
        arr  = @drawing.array().valueOf()
        tail = arr.length > 1 and arr[arr.length-2] or arr[arr.length-1]
        dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
        if arr.length < 2 or dist > 20
            arr.push [p.x, p.y]
        else
            last(arr)[0] = p.x
            last(arr)[1] = p.y
        @drawing.plot arr
                        
    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onDragStop: (drag, event) =>
        
        eventPos = @eventPos event
        stagePos = @stagePos event
        
        if @selection.rect?
            @selection.end eventPos
            return
        
        shape = @kali.shapeTool() 
            
        switch shape
            
            when 'loupe' 
                
                @selection.loupe.remove()
                delete @selection.loupe
                r = x:drag.startPos.x, y:drag.startPos.y, x2:drag.pos.x, y2:drag.pos.y
                normRect r
                @setViewBox x:r.x, y:r.y, width:r.x2-r.x, height:r.y2-r.y

        if @drawing
            
            if @drawing.width() == 0
                
                switch shape
                    when 'line' 
                        log 'empty line?'
                        @drawing.remember 'isPickPoly', true
                        return
                    when 'polygon', 'polyline'
                        log 'empty poly?'
                        @drawing.remember 'isPickPoly', true
                        return
                    when 'ellipse'
                        @drawing.width 50
                    else
                        @drawing.width 100
                    
                @drawing.cx stagePos.x
                
                switch shape
                    when 'circle'
                        @drawing.cy stagePos.y
                    
            if @drawing.height() == 0
                
                @drawing.height 100
                @drawing.cy stagePos.y
            
            if not @drawing.remember 'isPickPoly'
                
                delete @drawing

    endDrawing: ->
        
        if @drawing
            
            if @drawing.width() == 0 or @drawing.height() == 0
                @drawing.remove()
                
            delete @drawing
                
    # 000   000  000  00000000  000   000  
    # 000   000  000  000       000 0 000  
    #  000 000   000  0000000   000000000  
    #    000     000  000       000   000  
    #     0      000  00000000  00     00  
    
    onResize: (w, h) => @resetSize()
    eventPos: (event) -> pos event
    localPos: (event) -> @eventPos(event).sub @viewPos()
    stagePos: (event) -> @localPos(event).scale(1.0/@zoom).add @panPos()
    viewPos:  -> r = @element.getBoundingClientRect(); x:r.left, y:r.top
    viewSize: -> r = @element.getBoundingClientRect(); width:r.width, height:r.height
    
    # transformPoint: (x, y) ->
        # p.x = x - (@offset.x - window.pageXOffset)
        # p.y = y - (@offset.y - window.pageYOffset)
        # p.matrixTransform @m
        
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    zoomIn:  -> @setZoom @zoom * 1.1
    zoomOut: -> @setZoom @zoom * 0.9
    
    setZoom: (z) -> 
        @zoom = z
        @resetSize()

    panPos:    -> vb = @svg.viewbox(); pos vb.x, vb.y
    resetPan:  -> @panBy @panPos().scale -1
    resetView: -> @resetZoom(); @resetPan()
    resetZoom: -> @setZoom 1
        
    resetSize: ->
        
        box = @svg.viewbox()
        box.width  = @viewSize().width  / @zoom
        box.height = @viewSize().height / @zoom
        @setViewBox box

    setViewBox: (box) ->
        
        delete box.zoom
        @svg.viewbox box
        # log 'setViewBox', box, @svg.viewbox()
        box = @svg.viewbox()
        post.emit 'stage', 'viewbox', box
        post.emit 'stage', 'zoom',    box.zoom
        box
            
    # 00000000    0000000   000   000  
    # 000   000  000   000  0000  000  
    # 00000000   000000000  000 0 000  
    # 000        000   000  000  0000  
    # 000        000   000  000   000  
    
    panBy: (delta) ->
        
        box = @svg.viewbox()
        # log 'pan', box
        box.x -= delta.x / @zoom
        box.y -= delta.y / @zoom
        
        @setViewBox box
    
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event) ->

        switch combo
            
            when 'command+s'       then return @save()
            when 'command+o'       then return @load()
            when 'command+x'       then return @cut()
            when 'command+c'       then return @copy()
            when 'command+v'       then return @paste()
            when 'command+k'       then return @clear()
            when 'command+-'       then return @zoomOut()
            when 'command+='       then return @zoomIn()
            when 'command+0'       then return @resetView()
            when 'enter', 'return', 'esc' then return @endDrawing()                
        
        return if 'unhandled' != @resizer  .handleKey mod, key, combo, char, event
        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event
        
        'unhandled'
        
module.exports = Stage

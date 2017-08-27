
#  0000000  000000000   0000000    0000000   00000000  
# 000          000     000   000  000        000       
# 0000000      000     000000000  000  0000  0000000   
#      000     000     000   000  000   000  000       
# 0000000      000     000   000   0000000   00000000  

{ elem, post, drag, last, pos, log } = require 'kxk'
SVG = require 'svg.js'
sel = require 'svg.select.js'
rsz = require 'svg.resize.js'
drw = require 'svg.draw.js'
clr = require 'svg.colorat.js'
Selection = require './selection'

class Stage

    constructor: (@kali) ->

        @element = elem 'div', id: 'stage'
        @kali.element.appendChild @element
        @svg = SVG(@element).size '100%', '100%' 
        @svg.style
            'stroke-linecap': 'round'
            'stroke-linejoin': 'round'
        @svg.clear()
        @selection = new Selection @kali
        
        @drag = new drag
            target:  @element
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop

        window.area.on 'resized', @onResize
        @resetZoom()

    #  0000000  000   000   0000000   
    # 000       000   000  000        
    # 0000000    000 000   000  0000  
    #      000     000     000   000  
    # 0000000       0       0000000   
    
    setSVG: (svg) ->
        @clear()
        @svg.svg svg
        
    addSVG: (svg) ->
        @svg.svg svg
        
    clear: -> 
        @selection.clear()
        @svg.clear()
        
    dump: -> 

        items = @selection.empty() and @svg.children() or @selection.selected
        
        bb = null
        for item in items
            item.selectize false
            bb ?= item.rbox()
            bb = bb.merge item.rbox()
        bb = bb.transform new SVG.Matrix().translate -@viewPos().x, -@viewPos().y
        @grow bb
        
        log @getSVG items, bb
        
        if not @selection.empty()
            for item in @selection.selection
                item.selectize true

    save: -> 
        log 'save', @getSVG @svg.children(), x:0, y:0, width:@viewSize().width, height:@viewSize().height
        
    load: -> log 'load'
        
    getSVG: (items, bb) ->
        log 'dump', items.length

        svgStr = '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" '
        svgStr += "viewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        for item in items
            svgStr += item.svg()
        svgStr += '</svg>'
        svgStr
        
    handleKey: (mod, key, combo, char, event) ->

        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event
        'unhandled'
    
    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape, attr, style) ->
        
        if shape == 'triangle'
            e = @svg.polygon('0,-50 100,0 0,50')
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
    
    onDragStart: (drag, event) =>

        @kali.focus()
        
        shape = @kali.shapeTool()
        
        for s,k of {pick:event.metaKey, pan:event.altKey, loupe:event.ctrlKey}
            if k and shape != s
                @kali.tools[s].onClick()
                shape = s
        
        switch shape 
            when 'pick'
                e = event.target.instance
                if not e?
                    e = SVG.adopt event.target
                if e == @svg
                    if not event.shiftKey
                        @selection.clear()
                    @selection.start @eventPos event
                else
                    if not @selection.contains e
                        if not event.shiftKey
                            @selection.clear()
                        @selection.add e
                    else
                        if event.shiftKey
                            @selection.del e
            when 'pan'   then log 'pan'
            when 'loupe' then log 'loupe'
            else
                @selection.clear()
                @drawing = @addShape shape
                switch shape 
                    when 'triangle'
                        p = @localPos event
                        @drawing.translate p.x, p.y
                        delete @drawing
                    when 'polygon', 'polyline'
                        @drawing.draw 'point', event
                    else
                        @drawing.draw event

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onDragMove: (drag, event) =>

        shape = @kali.shapeTool()
                    
        switch shape
            
            when 'pan'   then @panBy drag.delta
            when 'loupe' 
                
                log 'move loupe', drag.pos, drag.deltaSum
                
            when 'pick'
                
                if @selection.rect?
                    @selection.clear() if not event.shiftKey
                    @selection.move @eventPos event
                else if not @selection.empty()
                    @selection.moveBy drag.delta
                
            when 'polygon', 'polyline'
                
                arr  = @drawing.array().valueOf()
                tail = arr.length > 1 and arr[arr.length-2] or arr[arr.length-1]
                p = @localPos event
                dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
                if arr.length < 2 or dist > 20
                    @drawing?.draw 'point', event
                else
                    @drawing?.draw 'update', event

    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onDragStop: (drag, event) =>
        
        if @selection.rect?
            @selection.end @eventPos event
            return
        
        switch @kali.shapeTool() 
            when 'loupe' then log 'loupe end', drag
            when 'polygon', 'polyline'
                @drawing?.draw 'done'
            else
                @drawing?.draw event
                
        @drawing = null
    
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    zoom: -> @svg.viewbox().zoom
    resetZoom: ->
        box = @svg.viewbox()
        box.width  = @viewSize().width
        box.height = @viewSize().height
        box.zoom = 1
        box.x = 0
        box.y = 0
        @setViewBox box
        
    zoomIn:  -> @setViewBox @grow @svg.viewbox(), -10
    zoomOut: -> @setViewBox @grow @svg.viewbox()
        
    panBy: (delta) ->
        box = @svg.viewbox()
        box.x -= delta.x / @zoom()
        box.y -= delta.y / @zoom()
        @setViewBox box
    
    # 000   000  000  00000000  000   000  
    # 000   000  000  000       000 0 000  
    #  000 000   000  0000000   000000000  
    #    000     000  000       000   000  
    #     0      000  00000000  00     00  
    
    onResize: (w, h) => @resetZoom()
    
    setViewBox: (box) ->
        @svg.viewbox box
        post.emit 'stage', 'viewbox', box
        post.emit 'stage', 'zoom',    box.zoom

    viewPos:  -> r = @element.getBoundingClientRect(); x:r.left, y:r.top
    viewSize: -> r = @element.getBoundingClientRect(); width:r.width, height:r.height
    eventPos: (event) -> pos event
    localPos: (event) -> @eventPos(event).sub @viewPos()
       
    #  0000000   00000000    0000000   000   000  
    # 000        000   000  000   000  000 0 000  
    # 000  0000  0000000    000   000  000000000  
    # 000   000  000   000  000   000  000   000  
    #  0000000   000   000   0000000   00     00  
    
    grow: (box, percent=10) ->

        w = box.width * percent / 100
        box.width = box.width + 2*w
        box.x -= w
        
        h = box.height * percent / 100
        box.height = box.height + 2*h
        box.y -= h
        
        if box.w?  then box.w  = box.width
        if box.h?  then box.h  = box.height
        if box.x2? then box.x2 = box.x + box.width
        if box.y2? then box.y2 = box.y + box.height
        if box.cx? then box.cx = box.x + box.w/2
        if box.cy? then box.cy = box.y + box.y/2
        
        if box.zoom? then box.zoom *= (100-2*percent)/100
        box
    
module.exports = Stage

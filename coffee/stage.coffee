
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
        @svg.clear()
        @selection = new Selection @kali
        log 'Stage.constructor', @svg.viewbox()
        @drag = new drag
            target:  @element
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop
        
    dump: -> 
        @resetZoom()
        items = @selection.empty() and @svg.children() or @selection.selected
        # log "Stage.dump #{items.length}:"
        bb = null
        for item in items
            bb ?= item.rbox()
            bb = bb.merge item.rbox()
        bb = bb.transform new SVG.Matrix().translate -@viewPos().x, -@viewPos().y
        @grow bb
        @svg.viewbox bb
        log @svg.svg()
        @resetZoom()
        
    handleKey: (mod, key, combo, char, event) ->

        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event
        'unhandled'
    
    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape, attr, style) ->
        
        e = @svg[shape]()
        e.style
            stroke:           @kali.tools.stroke.color
            'stroke-opacity': @kali.tools.stroke.alpha
            
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
        
    # 00     00   0000000   000   000   0000000  00000000  
    # 000   000  000   000  000   000  000       000       
    # 000000000  000   000  000   000  0000000   0000000   
    # 000 0 000  000   000  000   000       000  000       
    # 000   000   0000000    0000000   0000000   00000000  
    
    onDragStart: (drag, event) =>

        @kali.focus()
        
        shape = @kali.shapeTool()
        
        if shape != 'pick' and event.metaKey
            post.emit 'tool', 'activate', 'pick'
            shape = 'pick'
        
        if shape == 'pick'
            e = event.target.instance
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
        else
            @selection.clear()
            @drawing = @addShape shape
            switch shape 
                when 'polygon', 'polyline'
                    @drawing.draw 'point', event
                else
                    @drawing.draw event

    onDragMove: (drag, event) =>

        if @selection.rect?
            @selection.clear() if not event.shiftKey
            @selection.move @eventPos event
            return
        else if not @selection.empty()
            @selection.moveBy drag.delta
            return
            
        switch @kali.shapeTool() 
            when 'polygon', 'polyline'
                arr  = @drawing.array().valueOf()
                tail = arr.length > 1 and arr[arr.length-2] or arr[arr.length-1]
                p = @localPos event
                dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
                if arr.length < 2 or dist > 20
                    @drawing?.draw 'point', event
                else
                    @drawing?.draw 'update', event

    onDragStop: (drag, event) =>
        
        if @selection.rect?
            @selection.end @eventPos event
            return
        
        switch @kali.shapeTool() 
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
        delete box.zoom
        box.x = 0
        box.y = 0
        @svg.viewbox box
        
    zoomIn: ->
        @svg.viewbox @grow @svg.viewbox(), -10
        
    zoomOut: ->
        @svg.viewbox @grow @svg.viewbox()
    
    viewPos:  -> r = @element.getBoundingClientRect(); x:r.left, y:r.top
    viewSize: -> r = @element.getBoundingClientRect(); width:r.width, height:r.height
    eventPos: (event) -> p = pos event
    localPos: (event) -> p = pos event; p.sub @viewPos()
       
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
        
        box.zoom ?= box.zoom * (100-2*percent)/100
        box
    
module.exports = Stage

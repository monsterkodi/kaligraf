
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
        
        @drag = new drag
            target:  @element
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop
        
    dump: -> log 'Stage.dump', @svg.svg()

    handleKey: (mod, key, combo, char, event) ->

        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event
        'unhandled'
    
    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape, attr, style) ->
        
        # log 'addShape', shape
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
                p = @eventPos event
                if arr.length < 2 or Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y) > 20
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
       
    eventPos: (event) ->
        p = pos event
        # r = @element.getBoundingClientRect()
        # p.sub x:r.left, y:r.top
        
module.exports = Stage

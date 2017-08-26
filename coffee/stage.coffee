
#  0000000  000000000   0000000    0000000   00000000  
# 000          000     000   000  000        000       
# 0000000      000     000000000  000  0000  0000000   
#      000     000     000   000  000   000  000       
# 0000000      000     000   000   0000000   00000000  

{log, elem, post} = require 'kxk'
SVG    = require 'svg.js'
drg    = require 'svg.draggable.js'
sel    = require 'svg.select.js'
rsz    = require 'svg.resize.js'
drw    = require 'svg.draw.js'
clr    = require 'svg.colorat.js'

class Stage

    constructor: (@kali) ->

        stageElem = elem 'div', id: 'stage'
        @kali.element.appendChild stageElem
        @svg = @element = SVG(stageElem).size '100%', '100%' 
        @shapes = []
        @selected = []
        
        @svg.on 'mousedown', @mouseDown
        @svg.on 'mousemove', @mouseMove
        @svg.on 'mouseup',   @mouseUp
                                        
    addShape: (shape, attr) ->
        
        e = @svg[shape]()
        e.attr attr
        e.style
            fill:             @kali.tools.fill.color
            stroke:           @kali.tools.stroke.color
            'fill-opacity':   @kali.tools.fill.alpha
            'stroke-opacity': @kali.tools.stroke.alpha
        @shapes.push e
        e
        
    # 00     00   0000000   000   000   0000000  00000000  
    # 000   000  000   000  000   000  000       000       
    # 000000000  000   000  000   000  0000000   0000000   
    # 000 0 000  000   000  000   000       000  000       
    # 000   000   0000000    0000000   0000000   00000000  
    
    mouseDown: (event) =>
        
        if not event.shiftKey
            @deselect()
            
        shape = @kali.shapeTool()
        if shape == 'pick'
            e = event.target.instance
            if e != @svg
                e.selectize deepSelect: true
                e.resize snapToAngle: 15
                e.draggable()
                e._memory._draggable.start event
                @selected.push e
        else
            @drawing = @addShape shape
            if shape == 'polygon'
                @drawing.draw 'point', event
            else
                @drawing.draw event

    mouseMove: (event) =>
        
        shape = @kali.shapeTool()
        if shape == 'polygon'
            @drawing?.draw 'point', event

    mouseUp: (event) =>
        
        shape = @kali.shapeTool()
        if shape == 'polygon'
            @drawing?.draw 'done'
        else
            @drawing?.draw event
        @drawing = null
        
    deselect: () =>
        for s in @selected
            s.selectize false, deepSelect: true
            s.draggable false
            s.resize 'stop'
        @selected = []
        
module.exports = Stage

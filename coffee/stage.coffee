
#  0000000  000000000   0000000    0000000   00000000  
# 000          000     000   000  000        000       
# 0000000      000     000000000  000  0000  0000000   
#      000     000     000   000  000   000  000       
# 0000000      000     000   000   0000000   00000000  

{log, elem, post, drag, pos} = require 'kxk'
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
        @selection = new Selection @kali
        
        @drag = new drag
            target:  @element
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop
        
    dump: -> log 'Stage.dump', @svg.svg()

    handleKey: (mod, key, combo, char, event) ->
        # log "Stage.handleKey mod:#{mod} key:#{key} combo:#{combo} char:#{char}"
        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event
        'unhandled'
    
    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape) ->
        
        e = @svg[shape]()
        e.style
            fill:             @kali.tools.fill.color
            stroke:           @kali.tools.stroke.color
            'fill-opacity':   @kali.tools.fill.alpha
            'stroke-opacity': @kali.tools.stroke.alpha
        e
        
    # 00     00   0000000   000   000   0000000  00000000  
    # 000   000  000   000  000   000  000       000       
    # 000000000  000   000  000   000  0000000   0000000   
    # 000 0 000  000   000  000   000       000  000       
    # 000   000   0000000    0000000   0000000   00000000  
    
    onDragStart: (drag, event) =>

        @kali.focus()
        
        if not event.shiftKey
            @selection.clear()
            
        shape = @kali.shapeTool()
        if shape == 'pick'
            e = event.target.instance
            if e != @svg
                @selection.add e
        else
            @drawing = @addShape shape
            if shape == 'polygon'
                @drawing.draw 'point', event
            else
                @drawing.draw event

    onDragMove: (drag, event) =>

        if not @selection.empty()
            @selection.moveBy drag.delta
            return
            
        if @kali.shapeTool() == 'polygon'
            @drawing?.draw 'point', event

    onDragStop: (drag, event) =>
        
        if @kali.shapeTool() == 'polygon'
            @drawing?.draw 'done'
        else
            @drawing?.draw event
        @drawing = null
                
module.exports = Stage

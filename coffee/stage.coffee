
#  0000000  000000000   0000000    0000000   00000000  
# 000          000     000   000  000        000       
# 0000000      000     000000000  000  0000  0000000   
#      000     000     000   000  000   000  000       
# 0000000      000     000   000   0000000   00000000  

{log, elem} = require 'kxk'
SVG    = require 'svg.js'
drg    = require 'svg.draggable.js'
sel    = require 'svg.select.js'
rsz    = require 'svg.resize.js'
drw    = require 'svg.draw.js'
clr    = require 'svg.colorat.js'
Picker = require './picker'

class Stage

    constructor: (parent) ->

        stageElem = elem 'div', id: 'stage'
        parent.appendChild stageElem
        @svg = @element = SVG(stageElem).size '100%', '100%' 
        @shapes = []
        
        @picker = new Picker parent
        
        @svg.on 'mousedown', @mouseDown
        @svg.on 'mousemove', @mouseMove
        @svg.on 'mouseup',   @mouseUp
                
        # @add 'rect',
            # width:  100
            # height: 100
            # y:      100
            # fill:   '#f00'
#             
        # @add 'rect',
            # width:  500
            # height: 50
            # y:      '50%'
            # x:      200
            # fill:   '#0ff'
                        
    add: (type, attr={}) ->   
        
        @addShape @svg[type]().attr attr

    addShape: (e) ->
        e.draggable().on 'dragstart', @dragStart
        e.draggable().on 'dragmove',  @dragMove
        e.draggable().on 'dragend',   @dragEnd
        @shapes.push e
        e
        
    dragStart: (event) => 
        
        @deselect()
        e = event.target.instance
        e.selectize deepSelect:  true
        e.resize    snapToAngle: 15
        @selected = e
        
    dragMove:  (event) => 
        
    dragEnd:   (event) => 
        e = event.target.instance

    mouseDown: (event) =>
        @deselect()
        @drawing = @add 'polygon'
        @drawing.attr fill: 'white'
        @drawing.draw 'point', event

    mouseMove: (event) =>        
        @drawing?.draw 'point', event

    mouseUp: (event) =>
        @drawing?.draw 'done'
        @drawing = null
        
    deselect: () =>
        @selected?.selectize false, deepSelect: true
        delete @selected
        
module.exports = Stage

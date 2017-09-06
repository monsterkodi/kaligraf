
# 00000000  0000000    000  000000000
# 000       000   000  000     000   
# 0000000   000   000  000     000   
# 000       000   000  000     000   
# 00000000  0000000    000     000  

{ post, drag, elem, log, _ } = require 'kxk'

class Edit

    constructor: (@kali) ->

        @element = elem 'div', id: 'edit'
        @kali.element.appendChild @element
        
        @svg = SVG(@element).size '100%', '100%' 
        @svg.addClass 'editSVG'
        @svg.viewbox @kali.stage.svg.viewbox()
        @svg.clear()

        @drags  = []
        @points = []
        @ctrls  = []
        
        post.on 'draw',  @onDraw
        post.on 'stage', @onStage

    onStage: (action, box) =>
        
        if action == 'viewbox' 
            @svg.viewbox box
        
    del: ->
        
        for d in @drags
            d.deactivate()
        @drags = []
        
        post.removeListener 'stage', @onStage
        post.removeListener 'draw',  @onDraw
        
        @svg.clear()
        @svg.remove()
        @element.remove()
        
    addPoint: (index, p) ->
        
        point = @svg.circle(4).addClass 'editPoint'
        point.attr cx:p.x, cy:p.y
        point.style cursor: 'pointer'
        @points.push point
        @drags.push = new drag
            target:  point.node
            onStart: @onPointStart
            onMove:  @onPointMove

    updatePoint: (index, p) ->
        
        @points[index].attr cx:p.x, cy:p.y
            
    onPointStart: ->
    onPointMove:  ->
            
    onDraw: (draw, action, index) =>
        
        p = draw.posAt index
        log "Edit.onDraw action:#{action} index:#{index}", p
        switch action
            
            when 'append' then @addPoint    index, p
            when 'change' then @updatePoint index, p
        
        
module.exports = Edit

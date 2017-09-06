
# 00000000  0000000    000  000000000
# 000       000   000  000     000   
# 0000000   000   000  000     000   
# 000       000   000  000     000   
# 00000000  0000000    000     000  

{ post, drag, elem, pos, log, _ } = require 'kxk'

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
        post.on 'ctrl',  @onCtrl
        post.on 'stage', @onStage

    setItem: (item) ->
        
        return if not _.isFunction item.array?
        
        points = item.array().valueOf()
        for i in [0...points.length]
            p = switch item.type
                when 'polygon', 'polyline', 'line'
                    pos points[i][0], points[i][1]
                else
                    point = points[i]
                    pos point[point.length-2], point[point.length-1]
            p = pos new SVG.Point(p).transform item.transform().matrix
            @addPoint i, p
        
    onStage: (action, box) =>
        
        if action == 'viewbox' then @svg.viewbox box
        
    del: ->

        for d in @drags
            d.deactivate()
            
        @drags  = []
        @points = []
        @ctrls  = []
        
        post.removeListener 'stage', @onStage
        post.removeListener 'ctrl',  @onCtrl
        post.removeListener 'draw',  @onDraw
        
        @svg.clear()
        @svg.remove()
        @element.remove()
        
    addCtrl: (index, p) ->
        
        ctrl = @svg.circle(4).addClass 'editCtrl'
        ctrl.attr cx:p.x, cy:p.y
        ctrl.style cursor: 'pointer'
        @ctrls[index] = ctrl
        @drags.push = new drag
            target:  ctrl.node
            onStart: @onCtrlStart
            onMove:  @onCtrlMove

    updateCtrl: (index, p) ->
        
        @ctrls[index]?.attr cx:p.x, cy:p.y
            
    onCtrlStart: ->
    onCtrlMove:  ->
        
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
         
    onCtrl: (draw, action, index, p) =>
        
        switch action
            
            when 'append' then @addCtrl    index, p
            when 'change' then @updateCtrl index, p
        
        
    onDraw: (draw, action, index) =>
        
        p = draw.posAt index
        # log "Edit.onDraw action:#{action} index:#{index}", p
        switch action
            
            when 'append' then @addPoint    index, p
            when 'change' then @updatePoint index, p
        
        
module.exports = Edit

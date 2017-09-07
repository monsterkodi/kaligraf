
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
        
        @dotSize = 4
        
        @svg = SVG(@element).size '100%', '100%' 
        @svg.addClass 'editSVG'
        @svg.viewbox @kali.stage.svg.viewbox()
        @svg.clear()

        @trans  = @kali.trans
        
        @drags  = []
        @ctrls  = []
        
        post.on 'ctrl',  @onCtrl
        post.on 'stage', @onStage

    onStage: (action, box) => if action == 'viewbox' then @svg.viewbox box
            
    onCtrl: (draw, action, type, index, p) =>
        
        switch action
            
            when 'append' then @addCtrl    type, index, p
            when 'change' then @setPos type, index, p
        
    setItem: (item) ->
        
        @item = item
        
        if not _.isFunction item.array
            log "not an array item? #{item.id()} #{item.type}", item.array
            return
        
        points = item.array().valueOf()
        
        for i in [0...points.length]
            p = switch item.type
                when 'polygon', 'polyline', 'line'
                    pos points[i][0], points[i][1]
                else
                    point = points[i]
                    
                    switch point[0]
                        when 'C', 'c', 'S', 's', 'Q', 'q'
                            @addCtrl 'ctrl', i, @trans.transform item, pos point[1], point[2]
                            
                    switch point[0]
                        when 'C', 'c'
                            @addCtrl 'ctrl', i, @trans.transform item, pos point[3], point[4]
                            
                    pos point[point.length-2], point[point.length-1]
                    
            @addCtrl 'point', i, @trans.transform item, p
                
    del: ->

        for d in @drags
            d.deactivate()
            
        @drags  = []
        @ctrls  = []
        
        post.removeListener 'stage', @onStage
        post.removeListener 'ctrl',  @onCtrl
        
        @svg.clear()
        @svg.remove()
        @element.remove()
        
    addCtrl: (type, index, p) ->
        
        clss = type == 'point' and 'editPoint' or 'editCtrl'
        ctrl = @svg.circle(@dotSize).addClass clss
        ctrl.attr  cx:p.x, cy:p.y
        ctrl.style cursor: 'pointer'
        ctrl.remember 'index', index
        ctrl.remember 'type',  type
        @ctrls[index] ?= {}
        @ctrls[index][type] = ctrl
        @drags.push = new drag
            target:  ctrl.node
            onStart: @onCtrlStart
            onMove:  @onCtrlMove
            onStop:  @onCtrlStop
            
    setPos: (type, index, p) -> 
        
        if @ctrls[index]? and @ctrls[index][type]?
            @ctrls[index][type].attr  cx:p.x, cy:p.y
            
    onCtrlStart:  (drag, event) => @dragItem = event.target.instance
    onCtrlStop:   (drag, event) => delete @dragItem
    onCtrlMove:   (drag, event) =>
        
        stagePos = @kali.stage.stageForEvent pos event
        
        index = @dragItem.remember 'index'
        type  = @dragItem.remember 'type'
        
        @setPos type, index, stagePos

        inverse = @trans.inverse @item, stagePos
                
        points = @item.array().valueOf()
        point = points[index]
        
        switch type 
            
            when 'ctrl'
                switch point[0]
                    when 'C', 'c', 'S', 's', 'Q', 'q'
                        
                        point[1] = inverse.x 
                        point[2] = inverse.y
                        @item.plot @item.array()
                        
            when 'point'
                switch point[0]
                    when 'C', 'c', 'S', 's', 'Q', 'q', 'M', 'm', 'L', 'l'
                        
                        point[point.length-2] = inverse.x 
                        point[point.length-1] = inverse.y
                        @item.plot @item.array()
                            
module.exports = Edit

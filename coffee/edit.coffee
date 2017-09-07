
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

        @trans  = @kali.trans
        
        @dotSize = 4
        
        @drags  = []
        @ctrls  = []
        
        post.on 'ctrl',  @onCtrl
        post.on 'stage', @onStage

    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
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

    onStage: (action, box) => if action == 'viewbox' then @svg.viewbox box
            
    onCtrl: (draw, action, type, index, p) =>
        
        switch action
            
            when 'append' then @addCtrl type, index, p
            when 'change' then @setPos  type, index, p
        
    # 000  000000000  00000000  00     00  
    # 000     000     000       000   000  
    # 000     000     0000000   000000000  
    # 000     000     000       000 0 000  
    # 000     000     00000000  000   000  
    
    setItem: (item) ->
        
        @item = item
        
        if not _.isFunction item.array
            log "not an array item? #{item.id()} #{item.type}", item.array
            return
        
        points = item.array().valueOf()
        
        for i in [0...points.length]
            point = points[i]
            p = switch item.type
                
                when 'polygon', 'polyline', 'line'
                    pos point[0], point[1]
                else
                    pos point[point.length-2], point[point.length-1]
                    
            @addCtrl 'point', i, @trans.transform item, p
            
            switch item.type
                when 'polygon', 'polyline', 'line' then
                else
                    switch point[0]
                        when 'C', 'c', 'S', 's', 'Q', 'q'
                            @addCtrl 'ctrl1', i, @trans.transform item, pos point[1], point[2]
                            
                    switch point[0]
                        when 'C', 'c'
                            @addCtrl 'ctrl2', i, @trans.transform item, pos point[3], point[4]
                
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    addCtrl: (type, index, p) ->
        
        clss = type == 'point' and 'editPoint' or 'editCtrl'
        ctrl = @svg.circle(@dotSize).addClass clss
        ctrl.cx p.x 
        ctrl.cy p.y
        ctrl.style cursor: 'pointer'
        ctrl.remember 'index', index
        ctrl.remember 'type',  type
        @ctrls[index] ?= {}
        @ctrls[index][type] = ctrl
        
        if type in ['ctrl1', 'ctrl2']
            
            line = @svg.line().addClass "#{clss}Line"
            pp   = @ctrls[index]['point']
            line.plot [[pp.cx(), pp.cy()], [p.x, p.y]]
            line.back()
            @ctrls[index]["#{type}_line"] = line
        
        @drags.push = new drag
            target:  ctrl.node
            onStart: @onCtrlStart
            onMove:  @onCtrlMove
            onStop:  @onCtrlStop
            
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onCtrlStart:  (drag, event) => @dragItem = event.target.instance
    onCtrlStop:   (drag, event) => delete @dragItem
    onCtrlMove:   (drag, event) =>
        
        stagePos = @kali.stage.stageForEvent pos event
        
        index = @dragItem.remember 'index'
        type  = @dragItem.remember 'type'
        
        @setPos type, index, stagePos

        inverse = @trans.inverse @item, stagePos
                
        points = @item.array().valueOf()
        point  = points[index]
        
        switch type 
            
            when 'ctrl1', 'ctrl2'
                switch point[0]
                    when 'C', 'c', 'S', 's', 'Q', 'q'
                                                
                        point[1] = inverse.x 
                        point[2] = inverse.y
                        
                        line = @ctrls[index]["#{type}_line"]
                        pp   = @ctrls[index]['point']
                        line.plot [[pp.cx(), pp.cy()], [point[1], point[2]]]
                        
            when 'point'
                switch point[0]
                    when 'C', 'c', 'S', 's', 'Q', 'q', 'M', 'm', 'L', 'l'

                        dx = inverse.x - point[point.length-2]
                        dy = inverse.y - point[point.length-1]
                        
                        point[point.length-2] = inverse.x 
                        point[point.length-1] = inverse.y
                        
                switch point[0]
                    when 'C', 'c', 'S', 's', 'Q', 'q'
                        line = @ctrls[index]["ctrl1_line"]
                        pp   = @ctrls[index]['point']
                        cp   = @ctrls[index]['ctrl1']

                        if event.shiftKey
                            np = @getPos('ctrl1', index).plus pos dx, dy
                            @setPos 'ctrl1', index, np
                            point[1] = np.x 
                            point[2] = np.y
                            
                        line.plot [[pp.cx(), pp.cy()], [cp.cx(), cp.cy()]]
                        
                switch point[0]
                    when 'C', 'c'
                        line = @ctrls[index]["ctrl2_line"]
                        pp   = @ctrls[index]['point']
                        cp   = @ctrls[index]['ctrl2']

                        if event.shiftKey
                            np = @getPos('ctrl2', index).plus pos dx, dy
                            @setPos 'ctrl2', index, np
                            point[3] = np.x 
                            point[4] = np.y
                        
                        line.plot [[pp.cx(), pp.cy()], [cp.cx(), cp.cy()]]
                      
        @item.plot @item.array()

    # 00000000    0000000    0000000  
    # 000   000  000   000  000       
    # 00000000   000   000  0000000   
    # 000        000   000       000  
    # 000         0000000   0000000   
    
    getPos: (type, index, p) -> 
        if @ctrls[index]? and @ctrls[index][type]?
            @trans.center @ctrls[index][type]
            
    setPos: (type, index, p) -> 
        
        if @ctrls[index]? and @ctrls[index][type]?
            @ctrls[index][type].attr cx:p.x, cy:p.y
            
                        
module.exports = Edit

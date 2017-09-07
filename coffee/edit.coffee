
# 00000000  0000000    000  000000000
# 000       000   000  000     000
# 0000000   000   000  000     000
# 000       000   000  000     000
# 00000000  0000000    000     000

{ post, drag, elem, last, pos, log, _ } = require 'kxk'

{ rectOffset, normRect, rectsIntersect } = require './utils'

class Edit

    constructor: (@kali) ->

        @element = elem 'div', id: 'edit'
        @kali.element.appendChild @element

        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'editSVG'
        @svg.viewbox @kali.stage.svg.viewbox()
        @svg.clear()

        @stage     = @kali.stage
        @trans     = @kali.trans
        @selection = @stage.selection

        @dotSize = 10

        @items = []
        @drags = []
        @ctrls = []

        post.on 'ctrl',  @editCtrl
        post.on 'stage', @onStage

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        @clear()

        post.removeListener 'stage', @onStage
        post.removeListener 'ctrl',  @editCtrl

        @svg.remove()
        @element.remove()

    #  0000000  000      00000000   0000000   00000000
    # 000       000      000       000   000  000   000
    # 000       000      0000000   000000000  0000000
    # 000       000      000       000   000  000   000
    #  0000000  0000000  00000000  000   000  000   000

    clear: ->

        log "clear #{@items.length}"
        while @items.length
            @delItem last @items

        for d in @drags
            d.deactivate()

        @drags  = []
        @ctrls  = []

        @svg.clear()

    onStage: (action, box) => if action == 'viewbox' then @svg.viewbox box

    # 0000000    00000000  000      00000000  000000000  00000000  
    # 000   000  000       000      000          000     000       
    # 000   000  0000000   000      0000000      000     0000000   
    # 000   000  000       000      000          000     000       
    # 0000000    00000000  0000000  00000000     000     00000000  
    
    delete: ->
        
        if not @empty()
            for item in @items
                if item.parent()?.removeElement?
                    item.remove()
                else
                    item.clear()
                    item.node.remove()
        @clear()
    
    # 000  000000000  00000000  00     00
    # 000     000     000       000   000
    # 000     000     0000000   000000000
    # 000     000     000       000 0 000
    # 000     000     00000000  000   000

    empty: -> @items.length <= 0
    contains: (item) -> item in @items

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveBy: (delta) ->

        @stage.moveItems @items, delta

        offset = delta.times 1.0/@stage.zoom

        types = ['ctrl1', 'ctrl2', 'point', 'ctrl1_line', 'ctrl2_line']
        for ctrl in @ctrls
            for type in types
                if ctrl[type]?
                    @setPos ctrl, type, offset.plus @getPos ctrl, type

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    delItem: (item) ->

        if item in @items

            log "delItem #{item.id()}"

            for ctrl in @getCtrls item

                @delCtrl ctrl

            _.pull @items, item

    #  0000000   0000000    0000000
    # 000   000  000   000  000   000
    # 000000000  000   000  000   000
    # 000   000  000   000  000   000
    # 000   000  0000000    0000000

    addItem: (item) ->

        if item in @items then return

        log "addItem #{@items.length} #{item.id()}"

        @items.push item

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

            @editCtrl item, 'append', 'point', i, @trans.transform(item, p), point

            switch item.type
                when 'polygon', 'polyline', 'line' then
                else
                    switch point[0]
                        when 'C', 'c', 'S', 's', 'Q', 'q'
                            @editCtrl item, 'append', 'ctrl1', i, @trans.transform(item, pos point[1], point[2]), point

                    switch point[0]
                        when 'C', 'c'
                            @editCtrl item, 'append', 'ctrl2', i, @trans.transform(item, pos point[3], point[4]), point

    #  0000000  000000000  00000000   000       0000000
    # 000          000     000   000  000      000
    # 000          000     0000000    000      0000000
    # 000          000     000   000  000           000
    #  0000000     000     000   000  0000000  0000000

    getCtrls: (item) -> @ctrls.filter (ctrl) -> ctrl.item == item

    # 00000000  0000000    000  000000000
    # 000       000   000  000     000
    # 0000000   000   000  000     000
    # 000       000   000  000     000
    # 00000000  0000000    000     000

    editCtrl: (item, action, type, index, p, point) =>

        ctrls = @getCtrls item

        switch action
            
            when 'append'
                
                if index < ctrls.length
                    ctrl = ctrls[index]
                else
                    ctrl = item: item
                    @ctrls.push ctrl

                dot = @createDot ctrl, type, index, p

            when 'change'

                ctrl = ctrls[index]
                if not ctrl?
                    log "no ctrl? item:#{item.id()} index:#{index} type:#{type}"
                dot  = ctrl[type]

        if not dot?
            log action, type, index
                
        dot.cx p.x
        dot.cy p.y

    createDot: (ctrl, type, index, p) ->

        clss = type == 'point' and 'editPoint' or 'editCtrl'
        dot = @svg.circle(@dotSize).addClass clss
        dot.style cursor: 'pointer'
        dot.remember 'index', index
        dot.remember 'type',  type
        dot.remember 'ctrl',  ctrl

        ctrl[type] = dot

        if type in ['ctrl1', 'ctrl2']

            line = @svg.line().addClass "#{clss}Line"
            pp   = ctrl['point']
            line.plot [[pp.cx(), pp.cy()], [p.x, p.y]]
            line.back()
            ctrl["#{type}_line"] = line

        @drags.push = new drag
            target:  dot.node
            onStart: @onCtrlStart
            onMove:  @onCtrlMove
            onStop:  @onCtrlStop

        dot

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    delCtrl: (ctrl) ->

        for d in @drags
            if d.target == ctrl.node
                d.deactivate()
                _.pull @drags, d
                break

        ctrl.ctrl1?.remove()
        ctrl.ctrl2?.remove()
        ctrl.ctrl1_line?.remove()
        ctrl.ctrl2_line?.remove()
        ctrl.point?.remove()
        delete ctrl.item

        _.pull @ctrls, ctrl

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
        ctrl  = @dragItem.remember 'ctrl'

        item  = ctrl.item

        # log "Edit.onCtrlMove index:#{index} type:#{type}"

        @setPos ctrl, type, stagePos

        inverse = @trans.inverse item, stagePos

        points = item.array().valueOf()
        point  = points[index]

        log "Edit.onCtrlMove index:#{index} type:#{type} p[0]:#{point[0]}", stagePos, inverse
                            
        if item.type in ['polygon', 'polyline', 'line']

            point[0] = inverse.x
            point[1] = inverse.y

        else
            switch type

                when 'ctrl1', 'ctrl2'
                                        
                    switch point[0]
                        when 'C', 'c', 'S', 's', 'Q', 'q'

                            point[1] = inverse.x
                            point[2] = inverse.y

                            line = ctrl["#{type}_line"]
                            pp   = ctrl['point']
                            line.plot [[pp.cx(), pp.cy()], [stagePos.x, stagePos.y]]

                when 'point'

                    switch point[0]
                        when 'C', 'c', 'S', 's', 'Q', 'q', 'M', 'm', 'L', 'l'

                            dx = inverse.x - point[point.length-2]
                            dy = inverse.y - point[point.length-1]

                            point[point.length-2] = inverse.x
                            point[point.length-1] = inverse.y

                    switch point[0]
                        when 'C', 'c', 'S', 's', 'Q', 'q'
                            line = ctrl["ctrl1_line"]
                            pp   = ctrl['point']
                            cp   = ctrl['ctrl1']

                            if not event.shiftKey
                                np = @getPos(ctrl, 'ctrl1').plus pos dx, dy
                                @setPos ctrl, 'ctrl1', np
                                ip = @trans.inverse item, np
                                point[1] = ip.x
                                point[2] = ip.y

                            line.plot [[pp.cx(), pp.cy()], [cp.cx(), cp.cy()]]

                    switch point[0]
                        when 'C', 'c'
                            line = ctrl["ctrl2_line"]
                            pp   = ctrl['point']
                            cp   = ctrl['ctrl2']

                            if event.shiftKey
                                np = @getPos(ctrl, 'ctrl2').plus pos dx, dy
                                @setPos ctrl, 'ctrl2', np
                                point[3] = np.x
                                point[4] = np.y

                            line.plot [[pp.cx(), pp.cy()], [cp.cx(), cp.cy()]]

        item.plot item.array()

    # 00000000   00000000   0000000  000000000
    # 000   000  000       000          000
    # 0000000    0000000   000          000
    # 000   000  000       000          000
    # 000   000  00000000   0000000     000

    startRect: (p,o) ->

        @rect = x:p.x, y:p.y, x2:p.x, y2:p.y
        @pos = rectOffset @rect
        @updateRect o

    moveRect: (p,o) ->

        @rect.x2 = p.x
        @rect.y2 = p.y
        delete @pos
        @updateRect o

    endRect: (p) ->

        @rect.element.remove()
        delete @pos
        delete @rect

    updateRect: (opt={}) ->

        if not @rect.element
            @rect.element = @selection.addRect 'editRect'

        @selection.setRect @rect.element, @rect
        @addInRect @rect, opt

    addInRect: (rect, opt) ->

        r = normRect rect

        for child in @kali.items()

            rb = child.rbox()
            if rectsIntersect r, rb
                @addItem child
            else if not opt.join
                @delItem child

    # 00000000    0000000    0000000
    # 000   000  000   000  000
    # 00000000   000   000  0000000
    # 000        000   000       000
    # 000         0000000   0000000

    getPos: (ctrl, type, p) ->

        if ctrl[type]?
            pos ctrl[type].cx(), ctrl[type].cy()

    setPos: (ctrl, type, p) ->

        if ctrl[type]?
            ctrl[type].cx p.x
            ctrl[type].cy p.y

module.exports = Edit

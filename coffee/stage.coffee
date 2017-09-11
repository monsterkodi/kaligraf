
#  0000000  000000000   0000000    0000000   00000000
# 000          000     000   000  000        000
# 0000000      000     000000000  000  0000  0000000
#      000     000     000   000  000   000  000
# 0000000      000     000   000   0000000   00000000

{ resolve, elem, post, drag, stopEvent, last, clamp, pos, fs, log, _ } = require 'kxk'

{ growBox, normRect, boxForItems, bboxForItems, boxOffset, boxCenter } = require './utils'

{ clipboard } = require 'electron'

SVG       = require 'svg.js'
clr       = require 'svg.colorat.js'
Shapes    = require './shapes'
Selection = require './selection'
Resizer   = require './resizer'

class Stage

    constructor: (@kali) ->

        @element = elem 'div', id: 'stage'
        @kali.element.insertBefore @element, @kali.element.firstChild

        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'stageSVG'
        @svg.clear()

        @kali.stage = @

        @selection = new Selection @kali
        @resizer   = new Resizer   @kali
        @shapes    = new Shapes    @kali

        @kali.element.addEventListener 'wheel', @onWheel
        @element.addEventListener 'mousemove', @onMove

        post.on 'stage', @onStage
        post.on 'color', @onColor
        post.on 'line',  @onLine

        @zoom = 1
        @virgin = true

    onStage: (action, value) =>

        switch action

            when 'setColor' then @setColor value

    setColor: (c) ->

        @color = c
        @kali.element.style.background = @color

    # 000  000000000  00000000  00     00
    # 000     000     000       000   000
    # 000     000     0000000   000000000
    # 000     000     000       000 0 000
    # 000     000     00000000  000   000

    itemAtPos: (p) ->

        r = @svg.node.createSVGRect()
        r.x      = p.x - @viewPos().x
        r.y      = p.y - @viewPos().y
        r.width  = 1
        r.height = 1

        items = @svg.node.getIntersectionList r, null
        items = [].slice.call(items, 0).reverse()
        for item in items
            if item.instance in @items()
                return item.instance

    items: -> @svg.children().filter (child) -> child.type != 'defs'
    selectedOrAllItems: -> @selectedItems() ? @items()
    selectedItems: ->

        if not @selection.empty()
            @selection.items
        else if @shapes.edit? and not @shapes.edit.empty() 
            @shapes.edit.items()
        else
            []

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onMove: (event) =>

        if @kali.shapeTool() == 'loupe'
            @setCursor @kali.tools.ctrlDown and 'zoom-out' or 'zoom-in'

        @shapes.onMove event
            
    moveItems: (items, delta) ->

        for item in items
            @moveItem item, delta

    moveItem: (item, delta) ->

        center = @kali.trans.center item
        @kali.trans.center item, center.plus delta.times 1.0/@zoom

    #  0000000   0000000   000       0000000   00000000   
    # 000       000   000  000      000   000  000   000  
    # 000       000   000  000      000   000  0000000    
    # 000       000   000  000      000   000  000   000  
    #  0000000   0000000   0000000   0000000   000   000  
    
    onColor: (color, prop, value) =>
        
        attr = {}
        
        switch prop
            when 'alpha'
                attr[color + '-opacity'] = value
            when 'color'
                attr[color] = new SVG.Color value
                
        if not _.isEmpty attr
            for item in @selectedItems()
                item.style attr
                
    # 000      000  000   000  00000000  
    # 000      000  0000  000  000       
    # 000      000  000 0 000  0000000   
    # 000      000  000  0000  000       
    # 0000000  000  000   000  00000000  
    
    onLine: (prop, value) =>
        
        for item in @selectedItems()
            item.style switch prop
                when 'width' then 'stroke-width': value
        
    #  0000000  000   000   0000000
    # 000       000   000  000
    # 0000000    000 000   000  0000
    #      000     000     000   000
    # 0000000       0       0000000

    setSVG: (svg) ->

        @clear()
        @addSVG svg, select:false
        @resetView()

    addSVG: (svg, opt) ->

        e = elem 'div'
        e.innerHTML = svg

        if e.firstChild.tagName == 'svg'

            if e.firstChild.style.background
                @setColor e.firstChild.style.background

            svg = SVG.adopt e.firstChild
            if svg? and svg.children().length

                @selection.clear()

                for child in svg.children()
                    @svg.svg child.svg()
                    added = last @svg.children()
                    if added.type != 'defs' and opt?.select != false
                        @selection.addItem last @svg.children()

    getSVG: (items, bb, color) ->

        selected = _.clone @selection.items
        @selection.clear()

        svgStr = """
            <svg width="100%" height="100%"
            version="1.1"
            xmlns="http://www.w3.org/2000/svg" 
            """

        if color
            svgStr += """
            xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:svgjs="http://svgjs.com/svgjs"
            """

        style  = "stroke-linecap: round; stroke-linejoin: round; "
        style += "background: #{color};" if color
        svgStr += "\nstyle=\"#{style}\""
        svgStr += "\nviewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        for item in items
            svgStr += '\n'
            svgStr += item.svg()
        svgStr += '</svg>'

        @selection.setItems selected

        svgStr

    #  0000000   0000000   000   000  00000000
    # 000       000   000  000   000  000
    # 0000000   000000000   000 000   0000000
    #      000  000   000     000     000
    # 0000000   000   000      0      00000000

    save: ->

        bb = @svg.bbox()
        growBox bb

        svg = @getSVG @items(), bb, @color

        fs.writeFileSync resolve('~/Desktop/kaligraf.svg'), svg

    load: ->

        svg = fs.readFileSync resolve('~/Desktop/kaligraf.svg'), encoding: 'utf8'
        @setSVG svg

    #  0000000   0000000   00000000   000   000
    # 000       000   000  000   000   000 000
    # 000       000   000  00000000     00000
    # 000       000   000  000           000
    #  0000000   0000000   000           000

    copy: ->

        selected = _.clone @selection.items
        items = @selection.empty() and @items() or selected
        return if items.length <= 0

        @selection.clear()

        bb = bboxForItems items
        growBox bb

        svg = @getSVG items, bb
        clipboard.writeText svg

        delete @selection.pos
        for item in selected
            @selection.addItem item

        svg

    paste: ->

        delete @selection.pos
        @addSVG clipboard.readText()

    cut: ->

        if not @selection.empty()
            @copy()
            @selection.delete()

    clear: ->

        @shapes.edit?.clear()
        @selection.clear()
        @svg.clear()
        @resetView()

    #  0000000   00000000   0000000    00000000  00000000
    # 000   000  000   000  000   000  000       000   000
    # 000   000  0000000    000   000  0000000   0000000
    # 000   000  000   000  000   000  000       000   000
    #  0000000   000   000  0000000    00000000  000   000

    order: (order) ->

        for item in @selectedItems()
            item[order]()

    select: (select) ->

        switch select
            when 'none'
                if @shapes.edit? and not @shapes.edit.dotsel.empty()
                    @shapes.edit.dotsel.clear()
                else
                    @shapes.stopEdit()
                    @selection.clear()
            when 'all'
                if @shapes.edit? and not @shapes.edit.empty()
                    @shapes.edit.dotsel.addAll()
                else if @shapes.edit? or @kali.shapeTool() == 'edit'
                    @shapes.editItems @items()
                else
                    @selection.setItems @items()
            when 'invert'
                if @shapes.edit? and not @shapes.edit.empty()
                    @shapes.edit.dotsel.invert()
                else if @shapes.edit? or @kali.shapeTool() == 'edit'
                    @shapes.editItems @items().filter (item) => not @shapes.edit? or item not in @shapes.edit.items()
                else
                    @selection.setItems @items().filter (item) => item not in @selection.items
                

    # 000   000  000  00000000  000   000
    # 000   000  000  000       000 0 000
    #  000 000   000  0000000   000000000
    #    000     000  000       000   000
    #     0      000  00000000  00     00

    onResize: (w, h) => @resetSize()

    viewPos:  -> r = @element.getBoundingClientRect(); pos r.left, r.top
    viewSize: -> r = @element.getBoundingClientRect(); pos r.width, r.height

    stageForView:  (viewPos)  -> pos(viewPos).scale(1.0/@zoom).plus @panPos()
    viewForStage:  (stagePos) -> pos(stagePos).sub(@panPos()).scale @zoom
    viewForEvent:  (eventPos) -> eventPos.minus @viewPos()
    stageForEvent: (eventPos) -> @stageForView @viewForEvent eventPos

    #  0000000  00000000  000   000  000000000  00000000  00000000
    # 000       000       0000  000     000     000       000   000
    # 000       0000000   000 0 000     000     0000000   0000000
    # 000       000       000  0000     000     000       000   000
    #  0000000  00000000  000   000     000     00000000  000   000

    viewCenter:  -> pos(0,0).mid @viewSize()
    stageCenter: -> boxCenter @svg.viewbox()
    stageOffset: -> boxOffset @svg.viewbox()
    itemsCenter: -> @stageForEvent boxCenter boxForItems @items()

    centerAtStagePos: (stagePos) -> @moveViewBox stagePos.minus @stageCenter()

    # 000       0000000   000   000  00000000   00000000
    # 000      000   000  000   000  000   000  000
    # 000      000   000  000   000  00000000   0000000
    # 000      000   000  000   000  000        000
    # 0000000   0000000    0000000   000        00000000

    loupe: (p1, p2) ->

        viewPos1 = @viewForEvent pos p1
        viewPos2 = @viewForEvent pos p2
        viewPos  = viewPos1.mid viewPos2

        sc = @stageForView viewPos

        sd = @stageForView(viewPos1).sub @stageForView(viewPos2)
        dw = Math.abs sd.x
        dh = Math.abs sd.y

        if dw == 0 or dh == 0
            out = @kali.tools.ctrlDown
            @zoomAtPos viewPos, sc, out and 0.75 or 1.25
            return
        else
            vb = @svg.viewbox()
            zw = vb.width  / dw
            zh = vb.height / dh
            z = Math.min zw, zh

        if out then z = 1.0/z

        @setZoom @zoom * z, sc

    # 000   000  000   000  00000000  00000000  000
    # 000 0 000  000   000  000       000       000
    # 000000000  000000000  0000000   0000000   000
    # 000   000  000   000  000       000       000
    # 00     00  000   000  00000000  00000000  0000000

    onWheel: (event) =>

        eventPos = pos event
        viewPos  = @viewForEvent eventPos
        stagePos = @stageForView viewPos
        @zoomAtPos viewPos, stagePos, (1.0 - event.deltaY/5000.0)

    zoomAtPos: (viewPos, stagePos, factor) ->

        @setZoom @zoom * factor
        @panBy viewPos.minus @viewForStage stagePos

    # 0000000   0000000    0000000   00     00
    #    000   000   000  000   000  000   000
    #   000    000   000  000   000  000000000
    #  000     000   000  000   000  000 0 000
    # 0000000   0000000    0000000   000   000

    @zoomLevels = [
        0.01, 0.02, 0.05,
        0.10, 0.15, 0.20, 0.25, 0.33, 0.50, 0.75,
        1, 1.5, 2, 3, 4, 5, 6, 8,
        10, 15, 20, 40, 80,
        100, 150, 200, 400, 800,
        1000
    ]

    zoomIn: ->

        for i in [0...Stage.zoomLevels.length]
            if @zoom < Stage.zoomLevels[i]
                @setZoom Stage.zoomLevels[i], @stageCenter()
                return

    zoomOut: ->

        for i in [Stage.zoomLevels.length-1..0]
            if @zoom > Stage.zoomLevels[i]
                @setZoom Stage.zoomLevels[i], @stageCenter()
                return

    toolCenter: (zoom) ->

        vc = @viewCenter()
        vc.x = 560.5 if @viewSize().x > 1120
        vc.minus(pos(60.5,30.5)).scale(1/zoom)

    setCursor: (cursor) -> @svg.style cursor: cursor

    resetView: (zoom=1) => @setZoom zoom, @toolCenter zoom

    centerSelection: ->

        items = @selectedOrAllItems()
        if items.length <= 0
            @centerAtStagePos @toolCenter @zoom
            return

        b = boxForItems items, @viewPos()
        v = @svg.viewbox()
        w = (b.w / @zoom) / v.width
        h = (b.h / @zoom) / v.height
        z = 0.8 * @zoom / Math.max(w, h)

        @setZoom z, @stageForView boxCenter b

    setZoom: (z, sc) ->

        z = clamp 0.01, 1000, z

        @zoom = z
        @resetSize()
        @centerAtStagePos sc if sc?

    # 00000000    0000000   000   000
    # 000   000  000   000  0000  000
    # 00000000   000000000  000 0 000
    # 000        000   000  000  0000
    # 000        000   000  000   000

    panPos: -> vb = @svg.viewbox(); pos vb.x, vb.y

    panBy: (delta) -> @moveViewBox pos(delta).scale -1.0/@zoom

    # 000   000  000  00000000  000   000  0000000     0000000   000   000
    # 000   000  000  000       000 0 000  000   000  000   000   000 000
    #  000 000   000  0000000   000000000  0000000    000   000    00000
    #    000     000  000       000   000  000   000  000   000   000 000
    #     0      000  00000000  00     00  0000000     0000000   000   000

    resetSize: ->

        box = @svg.viewbox()

        box.width  = @viewSize().x / @zoom
        box.height = @viewSize().y / @zoom

        @setViewBox box

    moveViewBox: (delta) ->

        box = @svg.viewbox()

        box.x += delta.x
        box.y += delta.y

        @setViewBox box

    setViewBox: (box) ->

        delete box.zoom

        @svg.viewbox box

        box = @svg.viewbox()
        post.emit 'stage', 'viewbox', box
        post.emit 'stage', 'zoom',    @zoom
        box

    # 000   000  00000000  000   000
    # 000  000   000        000 000
    # 0000000    0000000     00000
    # 000  000   000          000
    # 000   000  00000000     000

    handleKey: (mod, key, combo, char, event, down) ->

        if down
            switch combo

                when 'command+-' then return @zoomOut()
                when 'command+=' then return @zoomIn()
                when 'command+0' then return @resetView()
                when 'enter', 'return', 'esc'
                    if combo == 'esc' then @shapes.handleEscape()
                    return @shapes.endDrawing()

                when 'left', 'right', 'up', 'down'
                    if @selectedItems().length
                        p = pos 0,0
                        switch key
                            when 'left'  then p.x = -1
                            when 'right' then p.x =  1
                            when 'up'    then p.y = -1
                            when 'down'  then p.y =  1
                        if @shapes.edit?
                            @shapes.edit.moveBy p
                        else
                            @resizer.moveBy p
                    
        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event, down
        return if 'unhandled' != @shapes   .handleKey mod, key, combo, char, event, down

        'unhandled'

module.exports = Stage

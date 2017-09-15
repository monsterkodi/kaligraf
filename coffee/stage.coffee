
#  0000000  000000000   0000000    0000000   00000000
# 000          000     000   000  000        000
# 0000000      000     000000000  000  0000  0000000
#      000     000     000   000  000   000  000
# 0000000      000     000   000   0000000   00000000

{   resolve, elem, post, drag, prefs, stopEvent, 
    first, last, empty, clamp, pos, fs, log, _ } = require 'kxk'

{   contrastColor, normRect, bboxForItems, 
    growBox, boxForItems, boxOffset, boxCenter } = require './utils'

electron  = require 'electron'
clipboard = electron.clipboard
dialog    = electron.remote.dialog

SVG       = require 'svg.js'
clr       = require 'svg.colorat.js'
Shapes    = require './shapes'
Selection = require './selection'
Resizer   = require './resizer'

class Stage

    constructor: (@kali) ->

        @element = elem 'div', id: 'stage'
        @kali.element.insertBefore @element, @kali.element.firstChild

        @currentFile = prefs.get 'currentFile', '~/Desktop/kaligraf.svg'
        
        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'stageSVG'
        @svg.clear()

        @kali.stage = @

        @selection = new Selection @kali
        @resizer   = new Resizer   @kali
        @shapes    = new Shapes    @kali

        @kali.element.addEventListener 'wheel', @onWheel
        @element.addEventListener 'mousemove', @onMove
        @element.addEventListener 'dblclick', @onDblClick
        
        @element.style.display = 'none'

        post.on 'stage', @onStage
        post.on 'color', @onColor
        post.on 'line',  @onLine
        post.on 'font',  @onFont

        @zoom   = 1
        # @virgin = true
        
        @setColor prefs.get('stage:color', '#222'), prefs.get('stage:alpha', 1)

    onStage: (action, color, alpha) =>

        switch action

            when 'setColor' then @setColor color, alpha
        
    foregroundColor: -> contrastColor @color

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
        # log items.length, p, @items().length
        for item in items
            if item.instance in @items()
                return item.instance
            else if item.instance in @treeItems()
                return @rootItem item.instance

    rootItem: (item) ->
        
        if item.parent() == @svg then item
        else @rootItem item.parent()

    items: -> @svg.children().filter (child) -> child.type != 'defs'
    
    treeItems: (item=@svg) -> 
        
        tree = []
        children = item.children?()
        if not empty children
            for child in children
                if child.type != 'defs'
                    tree.push child
                    tree = tree.concat @treeItems child
        tree
    
    selectedOrAllItems: -> 
        
        items = @selectedItems() 
        items = @items() if empty items
        items
        
    selectedItems: (opt) ->

        items = 
            if not @selection.empty()
                @selection.items
            else if @shapes.edit? and not @shapes.edit.empty() 
                @shapes.edit.items()
            else
                []
        if opt?.type?
            items = items.filter (item) -> item.type == opt.type
        items

    ungroup: ->
        
        oldItems = _.clone @items()
        
        for group in @selectedItems(type:'g')
            group.ungroup()
            
        @selection.clear()
        @selection.setItems @items().filter (item) -> item not in oldItems
        
    group: ->
        
        group = @svg.group()
        for item in @selectedItems()
           group.add item
           
        @selection.setItems [group]
            
    isEditableItem: (item) -> _.isFunction(item.array) and item.type != 'text'
            
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

    onDblClick: (event) =>
        
        item = @itemAtPos pos event
        if not item?
            window.main?.toggleMaximize()
        else
            if item.type == 'text'
                @kali.tools.activateTool 'text'
                @shapes.editTextItem item
            else
                log 'dblclick', item?.id()
        
    #  0000000   0000000   000       0000000   00000000   
    # 000       000   000  000      000   000  000   000  
    # 000       000   000  000      000   000  0000000    
    # 000       000   000  000      000   000  000   000  
    #  0000000   0000000   0000000   0000000   000   000  

    setColor: (color, @alpha) ->

        log "setColor a  #{@alpha}", color
        @color = new SVG.Color color
        @kali.element.style.background = @color.toHex()
        document.body.style.background = @color.toHex()
        
        prefs.set 'stage:color', @color.toHex()    
        prefs.set 'stage:alpha', @alpha   
    
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

    onFont: (prop, value) =>
        
        for item in @selectedItems(type:'text')
            item.font prop, value
            
        @selection.updateItems()
        @resizer.calcBox()
                
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
        # @resetView()

    addSVG: (svg, opt) ->

        e = elem 'div'
        e.innerHTML = svg

        for elemChild in e.children
            
            if elemChild.tagName == 'svg'
    
                if elemChild.style.background
                    @setColor elemChild.style.background
    
                svg = SVG.adopt elemChild
                if svg? and svg.children().length
    
                    @selection.clear()
    
                    for child in svg.children()
                        @svg.add child
                        added = last @svg.children()
                        if added.type != 'defs' and opt?.select != false
                            @selection.addItem last @svg.children()
                          
                    for item in @treeItems()
                        tag = item.node.tagName
                        if tag == 'metadata' or tag.startsWith 'sodipodi'
                            item.remove()
                            
                    return

    getSVG: (items, bb, color) ->

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

        svgStr

    # 000       0000000    0000000   0000000    
    # 000      000   000  000   000  000   000  
    # 000      000   000  000000000  000   000  
    # 000      000   000  000   000  000   000  
    # 0000000   0000000   000   000  0000000    
    
    setCurrentFile: (@currentFile) -> @load()
    
    load: (file=@currentFile) ->

        svg = fs.readFileSync resolve(file), encoding: 'utf8'
        @setSVG svg
        
        @pushRecent file
        
        # post.emit 'tool', 'center'
        
    open: ->

        opts =         
            title:'         Open'
            filters:        [ {name: 'SVG', extensions: ['svg']} ]
            properties:     ['openFile']
            
        dialog.showOpenDialog opts, (files) => 
            if file = first files
                @currentFile = file
                @load()
        
    #  0000000   0000000   000   000  00000000
    # 000       000   000  000   000  000
    # 0000000   000000000   000 000   0000000
    #      000  000   000     000     000
    # 0000000   000   000      0      00000000

    save: (file=@currentFile) ->

        bb = @svg.bbox()
        growBox bb

        svgStr = """
            <svg width="100%" height="100%"
            version="1.1"
            xmlns="http://www.w3.org/2000/svg" 
            xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:svgjs="http://svgjs.com/svgjs"
            """

        rgba = "#{@color.r}, #{@color.g}, #{@color.b}, #{@alpha}"

        svgStr += "\nstyle=\"stroke-linecap: round; stroke-linejoin: round; background: rgba(#{rgba});\""
        svgStr += "\nviewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        
        for item in @svg.children()
            svgStr += '\n'
            svgStr += item.svg()
            
        svgStr += '</svg>'
        
        fs.writeFileSync resolve(file), svgStr

    saveAs: ->

        opts =         
            title:          'Save As'
            defaultPath:    @currentFile
            filters:        [ {name: 'SVG', extensions: ['svg']} ]
            
        dialog.showSaveDialog opts, (file) => 
            if file?
                @currentFile = file
                @save()
                @pushRecent @currentFile


    pushRecent: (file) ->
        
        recent = prefs.get 'recent', []
        _.pull recent, file
        recent.push file
        prefs.set 'recent', recent
                
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
        # log 'clear'
        # @resetView()

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

        log 'loupe'
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
        log 'zoomIn'
        for i in [0...Stage.zoomLevels.length]
            if @zoom < Stage.zoomLevels[i]
                @setZoom Stage.zoomLevels[i], @stageCenter()
                return

    zoomOut: ->
        log 'zoomOut'
        for i in [Stage.zoomLevels.length-1..0]
            if @zoom > Stage.zoomLevels[i]
                @setZoom Stage.zoomLevels[i], @stageCenter()
                return

    toolCenter: (zoom) ->

        vc = @viewCenter()
        vc.x = 560.5 if @viewSize().x > 1120
        vc.minus(pos(@kali.toolSize+0.5,@kali.toolSize/2+0.5)).scale(1/zoom)

    setCursor: (cursor) -> @svg.style cursor: cursor

    resetView: (zoom=1) => 
        log 'resetView'
        @setZoom zoom, @toolCenter zoom

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

        log 'centerSelection'
        @setZoom z, @stageForView boxCenter b

    setZoom: (z, sc) ->

        z = clamp 0.01, 1000, z

        @zoom = z
        
        log 'setZoom'
        @resetSize()
        @centerAtStagePos sc if sc?

    zoomAtPos: (viewPos, stagePos, factor) ->

        @zoom = clamp 0.01, 1000, @zoom * factor
        
        delta = viewPos.minus @viewForStage stagePos
        delta.scale -1.0/@zoom
        
        box = @svg.viewbox()
        
        box.width  = @viewSize().x / @zoom
        box.height = @viewSize().y / @zoom
        box.x += delta.x
        box.y += delta.y
        log 'zoomAtPos'
        @setViewBox box
        
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

        log 'resetSize'
        @setViewBox box

    moveViewBox: (delta) ->

        box = @svg.viewbox()

        box.x += delta.x
        box.y += delta.y

        log 'moveViewBox'
        @setViewBox box

    setViewBox: (box) ->

        @svg.viewbox box

        box = @svg.viewbox()
        
        box.zoom = @zoom
        post.emit 'stage', 'viewbox', box
        post.emit 'stage', 'zoom',    @zoom
        
        prefs.set 'stage:viewbox', box
        
        log 'save viewbox', box
        
        box

    # 000   000  00000000  000   000
    # 000  000   000        000 000
    # 0000000    0000000     00000
    # 000  000   000          000
    # 000   000  00000000     000

    handleKey: (mod, key, combo, char, event, down) ->

        if down
            switch combo

                when 'command+-'        then return @zoomOut()
                when 'command+='        then return @zoomIn()
                when 'command+0'        then return @resetView()
                when 'enter', 'return'  then return @shapes.endDrawing()
                    
                when 'esc'
                    
                    if @shapes.handleEscape() then return
                    if @selection.clear()     then return
                    if @kali.shapeTool() != 'pick'
                        @kali.tools.getTool('pick').onClick()
                        return 

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

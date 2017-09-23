
#  0000000  000000000   0000000    0000000   00000000
# 000          000     000   000  000        000
# 0000000      000     000000000  000  0000  0000000
#      000     000     000   000  000   000  000
# 0000000      000     000   000   0000000   00000000

{   resolve, elem, post, drag, prefs, stopEvent, fileName,
    first, last, empty, clamp, pos, fs, log, _ } = require 'kxk'

{   contrastColor, normRect, bboxForItems, itemIDs,
    growBox, boxForItems, boxOffset, boxCenter } = require './utils'

electron  = require 'electron'
clipboard = electron.clipboard
dialog    = electron.remote.dialog

SVG       = require 'svg.js'
clr       = require 'svg.colorat.js'
Undo      = require './edit/undo'
Shapes    = require './edit/shapes'
Selection = require './selection'
Resizer   = require './resizer'
Exporter  = require './exporter'
Cursor    = require './cursor'

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
        @undo      = new Undo      @kali

        @kali.element.addEventListener 'wheel', @onWheel
        @element.addEventListener 'mousemove', @onMove
        @element.addEventListener 'dblclick', @onDblClick
        
        post.on 'stage', @onStage
        post.on 'line',  @onLine

        @zoom  = 1
        @alpha = 1
        
        @setColor prefs.get 'stage:color', 'rgba(32, 32, 32, 1)'
        
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  

    do:   (action) -> @undo.do @, action
    done:          -> @undo.done @
        
    state: ->
        
        selection: @selection.state()
        shapes:    @shapes.state()
        color:     @color.toHex()
        alpha:     @alpha
        svg:       @getSVG()
        
    restore: (state) ->
        
        @setSVG state.svg
        @setColor state.color, state.alpha
        @selection.restore state.selection
        @shapes.restore state.shapes
    
    onStage: (action, color, alpha) =>

        switch action

            when 'setColor' 
                @do 'stage color'
                @setColor color, alpha
                @done()
        
    foregroundColor: -> contrastColor @color

    # 000  000000000  00000000  00     00
    # 000     000     000       000   000
    # 000     000     0000000   000000000
    # 000     000     000       000 0 000
    # 000     000     00000000  000   000

    leafItemAtPos: (p) ->
        
        r = @svg.node.createSVGRect()
        r.x      = p.x - @viewPos().x
        r.y      = p.y - @viewPos().y
        r.width  = 1
        r.height = 1

        items = @svg.node.getIntersectionList r, null
        items = [].slice.call(items, 0).reverse()
        items = items.filter (item) -> item.instance
        items = items.map (item) -> item.instance

        for item in items
            if @isLeaf item
                log 'leafItemAtPos', item.id()
                return item
        log 'no leafItemAtPos', items.length
        null
    
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

    isLeaf:     (item) -> not _.isFunction item.children
    isEditable: (item) -> _.isFunction(item.array) and item.type != 'text'
    
    groups: -> @treeItems().filter (item) -> item.type == 'g'
    
    #  0000000  00000000  000      00000000   0000000  000000000  00000000  0000000    
    # 000       000       000      000       000          000     000       000   000  
    # 0000000   0000000   000      0000000   000          000     0000000   000   000  
    #      000  000       000      000       000          000     000       000   000  
    # 0000000   00000000  0000000  00000000   0000000     000     00000000  0000000    
    
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
        
    selectedLeafItems: ->
        
        # @selectedItems().filter (item) => not @isLeaf item
        
        items = []
        for item in @selectedItems()
            if @isLeaf item 
                items.push item
            else 
                items = items.concat @treeItems item
        items

    selectedNoTextItems: -> @selectedLeafItems().filter (item) -> item.type != 'text'
        
    sortedSelectedItems: (opt) ->
        
        items = @selectedItems opt
        items.sort (a,b) -> a.position() - b.position()
        items
                    
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onMove: (event) =>

        if @kali.shapeTool() == 'loupe'
            @kali.tools.getTool('loupe').onMove event

        @shapes.onMove event
            
    moveItems: (items, delta) ->

        @do 'move' + itemIDs items
        for item in items
            @moveItem item, delta
        @done()

    moveItem: (item, delta) ->

        center = @kali.trans.center item
        @kali.trans.center item, center.plus delta.times 1.0/@zoom

    onDblClick: (event) =>
        
        item = @leafItemAtPos pos event
        log 'onDblClick', item?
        if not item?
            # post.toMain 'maximizeWindow'
        else
            if item.type == 'text'
                @shapes.editTextItem item
            else if item.type in ['polygon', 'polyline', 'line', 'path']
                if item not in @selectedItems()
                    @selection.setItems [item]
                post.emit 'tool', 'click', 'edit'
            else
                log 'dblclick', item?.id()
        
    #  0000000   0000000   000       0000000   00000000   
    # 000       000   000  000      000   000  000   000  
    # 000       000   000  000      000   000  0000000    
    # 000       000   000  000      000   000  000   000  
    #  0000000   0000000   0000000   0000000   000   000  

    setColor: (color, alpha) ->

        if not alpha? 
            if color.startsWith 'rgba('
                split  = color.slice(5).split ','
                @alpha = parseFloat split[3]
                color  = "rgb(#{parseFloat split[0]}, #{parseFloat split[1]}, #{parseFloat split[2]})"
            else
                @alpha = 1
        else
            @alpha = alpha
            
        @color = new SVG.Color color
        
        @kali.element.style.background = @color.toHex()
        document.body.style.background = @color.toHex()
        
        post.emit 'stage', 'color', @color.toHex(), @alpha
        
        prefs.set 'stage:color', @color.toHex()    
        prefs.set 'stage:alpha', @alpha  
                    
    # 000      000  000   000  00000000  
    # 000      000  0000  000  000       
    # 000      000  000 0 000  0000000   
    # 000      000  000  0000  000       
    # 0000000  000  000   000  00000000  
    
    onLine: (prop, value) =>
        
        items = @selectedLeafItems()
        if not empty items
            log 'line'+ itemIDs items
            @do 'line'+ itemIDs items
            for item in items
                item.style switch prop
                    when 'width' then 'stroke-width': value
            @done()
        
    #  0000000  000   000   0000000
    # 000       000   000  000
    # 0000000    000 000   000  0000
    #      000     000     000   000
    # 0000000       0       0000000

    getSVG: -> Exporter.svg @svg, color:@color, alpha:@alpha
    
    setSVG: (svg) ->
        
        @clear @currentFile
        @addSVG svg, select:false, nodo:true
    
    addSVG: (svg, opt) ->

        e = elem 'div'
        e.innerHTML = svg

        for elemChild in e.children
            
            if elemChild.tagName == 'svg'
    
                if opt?.color != false
                    
                    if elemChild.style.background
                        @setColor elemChild.style.background
                    else
                        @setColor "#222", 0
    
                svg = SVG.adopt elemChild
                
                if svg? and svg.children().length
    
                    @do() if not opt?.nodo
                    @selection.clear()
                    
                    children = svg.children()
                    items = []
                                            
                    for child in children
                        @svg.add child
                        added = last @svg.children()
                        if added.type != 'defs' 
                            items.push added
                          
                    for item in @treeItems()
                        tag = item.node.tagName
                        if tag == 'metadata' or tag.startsWith 'sodipodi'
                            item.remove()

                    if opt.id?
                        
                        if items.length == 1 and first(items).type == 'g'
                            group = first items 
                        else
                            group = @svg.group()
                            
                        group.id opt.id
                        
                        for item in items
                           group.add item
                           
                        Exporter.cleanIDs @treeItems()
                        
                        @selection.setItems [group]
                    else                            
                        Exporter.cleanIDs @treeItems()
                    
                        if opt?.select != false
                            for item in items        
                                @selection.addItem item
                      
                    @done() if not opt?.nodo
                    return

    itemSVG: (items, bb, color) ->

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
    
    load: (file=@currentFile) ->

        @undo.clear()
        
        @currentFile = file
        
        try
            svg = fs.readFileSync resolve(file), encoding: 'utf8'
        catch e
            log "error:", e
            return

        @setSVG svg
            
        @pushRecent file
        
        @kali.closeBrowser()
        
        post.emit 'stage', 'load', @currentFile
        
    open: ->

        opts =         
            title:          'Open'
            filters:        [ {name: 'SVG', extensions: ['svg']} ]
            properties:     ['openFile']
            
        dialog.showOpenDialog opts, (files) => 
            if file = first files
                @load file 

    import: ->
        
        opts =         
            title:          'Import'
            filters:        [ {name: 'SVG', extensions: ['svg']} ]
            properties:     ['openFile', 'multiSelections']
            
        dialog.showOpenDialog opts, (files) => 
            if not empty files
                @do()
                for file in files
                    svg = fs.readFileSync file, encoding: 'utf8'
                    @addSVG svg, color:false, id:fileName file
                @done()
                
    #  0000000   0000000   000   000  00000000
    # 000       000   000  000   000  000
    # 0000000   000000000   000 000   0000000
    #      000  000   000     000     000
    # 0000000   000   000      0      00000000

    save: (file=@currentFile) ->

        @currentFile = file
        
        if @currentFile == 'untitled.svg'
            return @saveAs()
        
        Exporter.save @svg, file:@currentFile, color:@color, alpha:@alpha
                
        post.emit 'file', @currentFile
                        
    saveAs: ->

        opts =         
            title:          'Save As'
            defaultPath:    @currentFile
            filters:        [ {name: 'SVG', extensions: ['svg']} ]
            
        dialog.showSaveDialog opts, (file) => 
            if file?
                @save file 
                @pushRecent @currentFile

    pushRecent: (file) ->
        
        recent = prefs.get 'recent', []
        _.pull recent, file
        recent.unshift file
        prefs.set 'recent', recent
        
    export: ->
        
        opts =         
            title:          'Export'
            defaultPath:    @currentFile
            filters:        [ {name: 'SVG', extensions: ['svg']} ]
        
        dialog.showSaveDialog opts, (file) => 
            if file?
                fs.writeFileSync file, @copy(), encoding: 'utf8'
                
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

        svg = @itemSVG items, bb
        clipboard.writeText svg

        for item in selected
            @selection.addItem item

        svg

    paste: ->

        @do()
        @addSVG clipboard.readText(), color:false
        @done()

    cut: ->

        if not @selection.empty()
            @do()
            @copy()
            @selection.delete()
            @done()

    #  0000000  000      00000000   0000000   00000000   
    # 000       000      000       000   000  000   000  
    # 000       000      0000000   000000000  0000000    
    # 000       000      000       000   000  000   000  
    #  0000000  0000000  00000000  000   000  000   000  
    
    new: ->
        
        @undo.clear()
        @clear 'untitled.svg'
    
    doClear: -> 
        
        @do()
        @clear()
        @done()
    
    clear: (file=@currentFile) ->

        @currentFile = file
        @shapes.edit?.clear()
        @selection.clear()
        @svg.clear()
        
        post.emit 'file', @currentFile

    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
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

    toolCenter: (zoom) ->

        vc = @viewCenter()
        vc.x = 560.5 if @viewSize().x > 1120
        vc.minus(pos(@kali.toolSize+0.5,@kali.toolSize/2+0.5)).scale(1/zoom)

    setToolCursor: (tool, opt) -> @setCursor Cursor.forTool tool, opt
        
    setCursor: (cursor) -> @svg.style cursor: cursor

    resetView: (zoom=1) => 

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

        @setZoom z, @stageForView boxCenter b

    setZoom: (z, sc) ->

        z = clamp 0.01, 1000, z

        @zoom = z
        
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

    resetSize: =>

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

        @svg.viewbox box

        box = @svg.viewbox()
        
        box.zoom = @zoom
        post.emit 'stage', 'viewbox', box
        post.emit 'stage', 'zoom',    @zoom
        
        prefs.set 'stage:viewbox', box
        
        box

    # 000   000  00000000  000   000
    # 000  000   000        000 000
    # 0000000    0000000     00000
    # 000  000   000          000
    # 000   000  00000000     000

    handleKey: (mod, key, combo, char, event, down) ->

        if down
            switch combo

                when 'enter', 'return'  then return @shapes.endDrawing()
                    
                when 'esc'
                    
                    if @shapes.handleEscape() then return
                    if @selection.clear()     then return
                    if @kali.shapeTool() != 'pick'
                        post.emit 'tool', 'click', 'pick'
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

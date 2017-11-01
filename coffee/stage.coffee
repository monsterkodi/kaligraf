
#  0000000  000000000   0000000    0000000   00000000
# 000          000     000   000  000        000
# 0000000      000     000000000  000  0000  0000000
#      000     000     000   000  000   000  000
# 0000000      000     000   000   0000000   00000000

{   resolve, elem, post, drag, prefs, stopEvent, fileName,
    first, last, empty, clamp, pos, fs, log, _ } = require 'kxk'

{   contrastColor, normRect, bboxForItems, itemIDs, insideBox, itemBox, boxPos,
    growBox, rboxForItems, boxOffset, boxCenter, itemGradient, itemMatrix } = require './utils'

electron  = require 'electron'
clipboard = electron.clipboard
dialog    = electron.remote.dialog
screen    = electron.screen

SVG       = require 'svg.js'
flt       = require 'svg.filter.js'
Undo      = require './edit/undo'
Points    = require './edit/points'
Shapes    = require './edit/shapes'
Selection = require './selection'
ItemRes   = require './edit/itemres'
Exporter  = require './exporter'
Cursor    = require './cursor'

class Stage
    
    log: -> #log.apply log, [].slice.call arguments, 0
    
    constructor: (@kali) ->

        @name = 'Stage'
        @element = elem 'div', id: 'stage'
        @kali.element.insertBefore @element, @kali.element.firstChild

        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'stageSVG'
        @svg.id 'kaligraf'
        @svg.clear()
        
        @debug = SVG(@element).size '100%', '100%'
        @debug.addClass 'stageSVG'
        @debug.id 'debug'
        @debug.clear()

        @kali.stage = @
        @trans = @kali.trans

        @selection = new Selection @kali
        @resizer   = new ItemRes   @kali
        @shapes    = new Shapes    @kali
        @undo      = new Undo      @kali

        @kali.element.addEventListener 'wheel', @onWheel
        @element.addEventListener 'mousemove', @onMove
        @element.addEventListener 'dblclick', @onDblClick
        
        post.on 'stage',  @onStage
        post.on 'resize', @onResize

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
        layers:    @storeLayers()
        alpha:     @alpha
        aspect:    @kali.tool('aspect').state() 
        padding:   @kali.tool('padding').state() 
        svg:       @getSVG()
        
    restore: (state) ->
        
        @setSVG state.svg
        @setColor state.color, state.alpha
        @restoreLayers state.layers
        @kali.tool('aspect').restore state.aspect
        @kali.tool('padding').restore state.padding
        post.emit 'stage', 'restore'
        @selection.restore state.selection
        @shapes.restore state.shapes
    
    onStage: (action, color, alpha) =>

        switch action

            when 'setColor' 
                @do 'stage color'
                @setColor color, alpha
                @done()
        
    foregroundColor: -> contrastColor @color

    # 000       0000000   000   000  00000000  00000000    0000000  
    # 000      000   000   000 000   000       000   000  000       
    # 000      000000000    00000    0000000   0000000    0000000   
    # 000      000   000     000     000       000   000       000  
    # 0000000  000   000     000     00000000  000   000  0000000   
    
    getLayers: (opt) -> 
        
        layers = empty(@layers) and [@svg] or @layers
        if opt?.pickable
            layers = layers.filter (layer) -> not layer.data 'disabled'
        layers
        
    pickableLayers: -> @getLayers pickable:true 
    disabledLayers: -> @getLayers pickable:false

    # 00000000   000   0000000  000   000  
    # 000   000  000  000       000  000   
    # 00000000   000  000       0000000    
    # 000        000  000       000  000   
    # 000        000   0000000  000   000  
    
    pickRect: (p) ->
        
        r = @svg.node.createSVGRect()
        r.x      = p.x - @viewPos().x
        r.y      = p.y - @viewPos().y
        r.width  = 1
        r.height = 1
        r
    
    pickItems: (eventPos, opt) ->
        
        pickableLayers = @pickableLayers()
        items = @svg.node.getIntersectionList @pickRect(eventPos), null
        items = [].slice.call(items, 0).reverse()
        for item in items
            if not item.instance?
                SVG.adopt item
        items = items.filter (item) => item.instance? and item.instance != @svg
        items = items.map (item) -> item.instance
        items = items.filter (item) => @layerForItem(item) in pickableLayers
            
        stagePos = @stageForEvent eventPos
        items   = items.filter (item) => insideBox stagePos, @trans.rect item
        oddeven = items.filter (item) => new Points(@kali,item).oddEvenTest stagePos
        if oddeven.length
            items = oddeven
        # else if items.length
            # log 'missed oddeven', items.length
        items = @filterItems items, opt
        items
        
    itemAtPos: (p, opt) ->
        
        for item in @pickItems(p, opt)
            if item in @pickableItems()
                return item
            else if item in @treeItems()
                return @rootItem item
        null

    leafItemAtPos: (p, opt) ->

        for item in @pickItems(p, opt)
            if @isLeaf item
                return item
        null
        
    pickableItems: (opt) -> 
        
        pickableLayers = @pickableLayers()
        @items(opt).filter (item) => @layerForItem(item) in pickableLayers
                        
    # 000  000000000  00000000  00     00
    # 000     000     000       000   000
    # 000     000     0000000   000000000
    # 000     000     000       000 0 000
    # 000     000     00000000  000   000
    
    items: (opt) -> 
        
        items = []
        for layer in @getLayers()
            items = items.concat layer.children()
        items = items.filter (item) -> item.type != 'defs'
        @filterItems items, opt

    rootItem: (item) ->
        
        if item.parent() in @getLayers() then item
        else @rootItem item.parent()

    editableItems: (opt) ->
        
        @treeItems pickable:true, noTypes: ['g', 'mask', 'clipPath']

    isEditable: (item) -> 
        
        return true if itemGradient(item, 'fill') or itemGradient(item, 'stroke')
        return true if Points.isFakeItem item
        _.isFunction item.array 
            
    groups: -> @treeItems pickable:false, type:'g' 
    
    treeItems: (opt) ->
        
        item = opt?.item ? @svg
        items = [] 
        if item != @svg and item.type != 'defs' and item not in @getLayers()
            items = @filterItems [item], opt

        if item.type != 'defs'
            for child in item.children?() ? []
                o = _.clone opt ? {}
                o.item = child
                items = items.concat @treeItems o
            
        items
        
    isLeaf: (item) -> not _.isFunction item.children
        
    # 00000000  000  000      000000000  00000000  00000000   
    # 000       000  000         000     000       000   000  
    # 000000    000  000         000     0000000   0000000    
    # 000       000  000         000     000       000   000  
    # 000       000  0000000     000     00000000  000   000  
    
    filterItems: (items, opt) ->
        
        return items if not opt?
        
        items.filter (item) => 
            if opt.pickable then return false if @layerForItem(item) not in @pickableLayers()
            if opt.noType   then return false if item.type == opt.noType
            if opt.noTypes  then return false if item.type in opt.noTypes
            if opt.type     then return item.type == opt.type
            if opt.types    then return item.type in opt.types
            return true
    
    #  0000000  00000000  000      00000000   0000000  000000000  00000000  0000000    
    # 000       000       000      000       000          000     000       000   000  
    # 0000000   0000000   000      0000000   000          000     0000000   000   000  
    #      000  000       000      000       000          000     000       000   000  
    # 0000000   00000000  0000000  00000000   0000000     000     00000000  0000000    
    
    selectedOrAllItems: -> 
        
        items = @selectedItems() 
        items = @pickableItems() if empty items
        items
        
    selectedItems: (opt) ->

        items = 
            if not @selection.empty()
                @selection.items
            else if @shapes.edit? and not @shapes.edit.empty() 
                @shapes.edit.items()
            else
                []

        @filterItems items, opt

    selectedLeafOrAllItems: ->
        
        selectedItems = @selectedLeafItems()
        
        if empty selectedItems
            selectedItems = @treeItems @kali.tool('select').shapeTextOpt()

        selectedItems
        
    selectedLeafItems: (opt) ->
             
        selectedItems = @selectedItems()
        return [] if empty selectedItems
        
        if not opt?
            opt = @kali.tool('select').shapeTextOpt()
        
        items = []
        for item in selectedItems
            if @isLeaf item 
                items = items.concat @filterItems [item], opt
            else 
                o = _.clone opt
                o.item = item
                items = items.concat @treeItems o
                
        items = @filterItems(items, noType: 'g') if opt?.type != 'g'
        items

    selectedNoTextItems: -> @selectedLeafItems noType:'text'
    selectedTextItems:   -> @selectedLeafItems type:'text'
        
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
            @kali.tool('loupe').onMove event

        @shapes.onMove event
            
    moveItemsBy: (items, delta) ->

        @do 'move' + itemIDs items
        for item in items
            center = @trans.center item
            @trans.center item, center.plus delta
            
        post.emit 'stage', 'moveItems', items:items, delta:delta
        @done()

    # 0000000    0000000    000       0000000  000      000   0000000  000   000  
    # 000   000  000   000  000      000       000      000  000       000  000   
    # 000   000  0000000    000      000       000      000  000       0000000    
    # 000   000  000   000  000      000       000      000  000       000  000   
    # 0000000    0000000    0000000   0000000  0000000  000   0000000  000   000  
    
    onDblClick: (event) =>

        if item = @leafItemAtPos pos event
            switch item.type 
                when 'text' then @shapes.editTextItem item
                when 'polygon', 'polyline', 'line', 'path'
                    if item not in @selectedItems()
                        @selection.setItems [item]
                    post.emit 'tool', 'click', 'edit'
                when 'image'
                    @loadImage item
                else
                    log 'Stage.onDblClick', item?.id()
        else
            post.emit 'fill', color:@color, alpha:@alpha

    loadImage: (item) ->
        
        opts =         
            title:      'Open Image'
            filters:    [ {name: 'Image', extensions: ['png', 'jpg', 'jpeg', 'gif']} ]
            properties: ['openFile']
        
        dialog.showOpenDialog opts, (files) => 
            if file = first files
                stage = @kali.stage
                item.load 'file://' + file
                item.loaded (loader) ->
                    @size loader.width, loader.height
                    stage.selection.update()
                    stage.resizer.update()
                    
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
        
        post.emit 'stage', 'color', color:@color, hex:@color.toHex(), alpha:@alpha
        
        prefs.set 'stage:color', @color.toHex()    
        prefs.set 'stage:alpha', @alpha  
                            
    #  0000000  000   000   0000000
    # 000       000   000  000
    # 0000000    000 000   000  0000
    #      000     000     000   000
    # 0000000       0       0000000

    getSVG: -> Exporter.svg @svg, color:@color, alpha:@alpha
    
    setSVG: (svg) ->
        
        @clear @currentFile
        @addSVG svg, select:false, nodo:true
    
    addSVG: (svgStr, opt) ->

        e = elem 'div'
        e.innerHTML = svgStr
                
        parent = opt?.parent ? @activeLayer()

        for elemChild in e.children
            
            if elemChild.tagName == 'svg'
    
                if opt?.color != false
                    if elemChild.style.background
                        @setColor elemChild.style.background
                    else
                        @setColor "#333", 0
    
                svg = SVG.adopt elemChild
                
                if svg? and svg.children().length
    
                    @do() if not opt?.nodo
                    @selection.clear()
                    
                    children = svg.children()
                    items = []
                                            
                    for child in children
                        if child.type == 'defs'
                            for defsChild in child.children()
                                parent.doc().defs().add defsChild
                        else if opt?.id and child.type == 'svg'
                            g = svg.group()
                            for layerChild in child.children()
                                layerChild.toParent g
                            items.push g
                        else
                            items.push child
                          
                    if opt?.id?
                        
                        if items.length == 1 and first(items).type == 'g'
                            group = first items 
                        else
                            group = svg.group()
                            
                        group.id opt.id
                        
                        for item in items
                           group.add item if item != group
                           
                        items = [group]
                           
                    for item in items
                        parent.add item
                        
                    Exporter.cleanIDs @treeItems()
                    Exporter.fixGradients parent.doc()
                    
                    if opt?.select != false
                        for item in items        
                            @selection.addItem item
                      
                    @done() if not opt?.nodo
                    return viewbox:svg.viewbox(), items:items
                else
                    log 'dafuk? empty?', svg?
                    

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

        info = @setSVG svg, parent:@svg
        
        @pushRecent file
        
        @kali.closeBrowser()
        
        post.emit 'stage', 'layer', active:-1, num:0
        
        @loadLayers()
        
        info.file = @currentFile
        
        @postLayer()
        
        post.emit 'stage', 'load', info
        
        @kali.focus()
                
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
                    @addSVG svg, 
                        color:  false
                        id:     fileName file
                        parent: @activeLayer()
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
        
        post.emit 'stage', 'willSave', file:@currentFile
            
        padding = @kali.tool('padding').percent
        Exporter.save @svg, file:@currentFile, color:@color, alpha:@alpha, box:@paddingBox()
                
        post.emit 'stage', 'save', file:@currentFile
                        
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
            filters:        [ {name: 'SVG,Image', extensions: ['svg', 'png', 'webp', 'jpg']} ]
        
        dialog.showSaveDialog opts, (file) => 
            if file?
                Exporter.export @svg, file, padding:@kali.tool('padding').percent
                
    #  0000000   0000000   00000000   000   000
    # 000       000   000  000   000   000 000
    # 000       000   000  00000000     00000
    # 000       000   000  000           000
    #  0000000   0000000   000           000

    copy: ->

        items = @selectedOrAllItems()
        return if items.length <= 0
        
        selected = _.clone @selection.items

        @selection.clear()

        bb = bboxForItems items
        growBox bb

        svg = Exporter.itemSVG items, viewbox:bb
        clipboard.writeText svg

        for item in selected
            @selection.addItem item

        svg

    paste: ->

        @do()
        info = @addSVG clipboard.readText(), color:false
        viewbox = info.viewbox
        mousePos = pos screen.getCursorScreenPoint()
        log 'CursorScreenPoint', mousePos
        # log 'items', info.items.length
        itemBox = bboxForItems info.items
        # log 'itemBox', itemBox
        boxCenter = boxPos itemBox, 'center'
        # log 'boxCenter', boxCenter        
        log 'window', window.screenX, window.screenY
        mousePos.sub pos window.screenX, window.screenY
        log 'mousePos', mousePos
        stagePos = @stageForView mousePos
        log 'stagePos', stagePos
        delta = stagePos.minus boxCenter 
        log 'delta', delta
        @moveItemsBy info.items, delta
        @selection.setItems info.items
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

        @layers = []
        @layerIndex = 0
        
        @currentFile = file

        @shapes.edit?.clear()
        @selection.clear()
        @svg.clear()
        @debug.clear()
        
        @postLayer()
        
        post.emit 'stage', 'clear', file:@currentFile
                
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
    itemsCenter: -> @stageForEvent boxCenter rboxForItems @items()

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

    #  0000000  000   000  00000000    0000000   0000000   00000000   
    # 000       000   000  000   000  000       000   000  000   000  
    # 000       000   000  0000000    0000000   000   000  0000000    
    # 000       000   000  000   000       000  000   000  000   000  
    #  0000000   0000000   000   000  0000000    0000000   000   000  
    
    setToolCursor: (tool, opt) -> @setCursor Cursor.forTool tool, opt
        
    setCursor: (cursor) -> @svg.style cursor: cursor
                
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

    onResize: => @resetSize()
    
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
        
        @debug.viewbox box
        @debug.style 'stroke-width': 1/@zoom
        
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

            switch key
                
                when 'left', 'right', 'up', 'down'
                    
                    return 'unhandled' if mod.includes 'command'
                    
                    if @selectedItems().length
                        p = pos 0,0
                        s = 1
                        if mod.includes 'shift' then s*=5
                        if mod.includes 'ctrl'  then s*=10
                        if mod.includes 'alt'   then s*=20
                        switch key
                            when 'left'  then p.x = -s
                            when 'right' then p.x =  s
                            when 'up'    then p.y = -s
                            when 'down'  then p.y =  s
                        if @shapes.edit?
                            @shapes.edit.moveBy p
                        else
                            @resizer.moveBy p

        if @kali.gradientEdit?
            return if 'unhandled' != @kali.gradientEdit.handleKey mod, key, combo, char, event, down
        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event, down
        return if 'unhandled' != @shapes   .handleKey mod, key, combo, char, event, down

        'unhandled'
            
module.exports = Stage

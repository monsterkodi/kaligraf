###
 0000000  000000000   0000000    0000000   00000000
000          000     000   000  000        000
0000000      000     000000000  000  0000  0000000
     000     000     000   000  000   000  000
0000000      000     000   000   0000000   00000000
###

{ elem, post, drag, prefs, stopEvent, first, last, empty, clamp, pos, slash, fs, log, _ } = require 'kxk'

{ contrastColor, normRect, bboxForItems, itemIDs, insideBox, itemBox, boxPos, uuid, 
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
        
        log '@kali.element', @kali.element?, @kali.element.children.length
        
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
    
    onStage: (action, arg1, arg2) =>

        switch action

            when 'setColor'
                
                @do 'stage color'
                @setColor arg1, arg2
                @done()
                
            when 'loadFile'
                
                if not arg1.dir
                    @load arg1.file
                else
                    if arg1.file == 'Recent' 
                        post.emit 'browser', 'browseRecent'
                    else
                        post.emit 'browser', 'browseDir', arg1
                        
            when 'saveFile'
                @save()
                
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

    activateSelectionLayer: ->

        return if not @numLayers()
        return if @selection.empty()
        noItems = @selectedItems().filter (item) -> not item?
        @activateLayer _.max @selectedItems().map (item) => @indexOfLayer @layerForItem item
    
    # 000       0000000    0000000   0000000  
    # 000      000   000  000   000  000   000
    # 000      000   000  000000000  000   000
    # 000      000   000  000   000  000   000
    # 0000000   0000000   000   000  0000000  

    loadLayers: ->

        gotSvg = false
        gotGrp = false

        for item in @items()
            if item.type == 'svg'
                gotSvg = true
            else if item.type != 'defs'
                gotGrp = true

        return false if not gotSvg

        if gotGrp
            newLayer = @svg.nested()
            newLayer.id "layer #{@numLayers()}"
            log 'Layer.loadLayers -- non svg stuff on top level:'
            for item in @items()
                if item.type not in ['svg', 'defs']
                    log "Layer.loadLayers -- moving item of type #{item.type} into new layer"
                    newLayer.add item

        layerIDs = []

        for item in @items()

            id = item.id()
            if id in layerIDs or not id.startsWith 'S-'
                id = uuid item
                item.id id
            layerIDs.push id

            transform = item.transform()
            if not _.isEqual transform.matrix, new SVG.Matrix()
                log 'Layer.loadLayers -- top level layer with transform?', transform

        layerIDs = @items().map (item) -> item.id()
        @log 'Layer.loadLayers', layerIDs

        @layers = []
        for id in layerIDs
            @layers.push SVG.get id
            @applyLayerState @layers.length-1, 'hidden'
            @applyLayerState @layers.length-1, 'disabled'

    numLayers: -> @getLayers().length
    layerAt:    (index) -> @getLayers()[@clampLayer index]
    clampLayer: (index) -> clamp 0, @numLayers()-1, index
    postLayer: ->
        info =
            active:     @layerIndex
            num:        @numLayers()
            hidden:     @activeLayer().data 'hidden'
            disabled:   @activeLayer().data 'disabled'
        @log "Layer.postLayer", info
        post.emit 'stage', 'layer', info

    #  0000000    0000000  000000000  000  000   000  00000000
    # 000   000  000          000     000  000   000  000
    # 000000000  000          000     000   000 000   0000000
    # 000   000  000          000     000     000     000
    # 000   000   0000000     000     000      0      00000000

    layerForItem: (item) ->

        parents = item.parents()
        if parents[parents.length-2] in @getLayers()
            parents[parents.length-2]
        else
            parents[parents.length-1]

    indexOfLayer: (layer) -> Math.max 0, @layers.indexOf layer

    activeLayer: -> @layerAt @layerIndex
    
    activateLayer: (index) ->
        @layerIndex = @clampLayer index
        @log 'Layer.activateLayer', index, @layerIndex
        @postLayer()

    storeLayers: ->

        layerIndex: @layerIndex
        layers:     @layers.map (layer) -> layer.id()

    restoreLayers: (state) ->

        @activateLayer state.layerIndex
        layerIDs    = state.layers
        if not _.isEqual(layerIDs, @layers.map (layer) -> layer.id())
            @layers = []
            for id in layerIDs
                @layers.push SVG.get id
            @postLayer()

    #  0000000   0000000    0000000
    # 000   000  000   000  000   000
    # 000000000  000   000  000   000
    # 000   000  000   000  000   000
    # 000   000  0000000    0000000

    duplicateLayer: (index=@layerIndex) ->

        @selection.setItems @layerAt(index).children()
        @createLayer selection:'copy', index:index+1

    splitLayer: (index=@layerIndex) ->

        selected = @selectedItems()
        items = selected.filter (item) => 
            index == @indexOfLayer @layerForItem item
        if not empty items
            @selection.setItems items
            log 'splitLayer', index+1
            @createLayer selection:'move', index:index+1
            @selection.setItems selected

    createLayer: (opt) ->

        index = opt?.index ? @layerIndex+1

        @do() if not opt?.nodo
        
        if empty @layers
            
            items = @items()
            
            disabled = @svg.data 'disabled'
            hidden   = @svg.data 'hidden'
            
            @svg.data 'disabled', null
            @svg.data 'hidden',   null
            
            @applyLayerState 0, 'hidden'
            @applyLayerState 0, 'disabled'
            
            layer = @svg.nested()
            layer.id "layer #{@numLayers()}"
            
            for item in items
                item.toParent layer
            
            layer.data 'disabled', true if disabled
            layer.data 'hidden',   true if hidden
            
            @layers.push layer

        layer = @svg.nested()
        layer.id "layer #{@numLayers()}"
        
        if index <= @numLayers()-1
            @layerAt(index).before layer

        @layers.splice index, 0, layer

        switch opt.selection
            when 'move'
                for item in @selectedItems()
                    item.toParent layer
            when 'copy'
                for item in @selectedItems()
                    item.clone().addTo layer
            when 'keep' then
            else
                log 'Layer.createLayer wrong option?', opt

        if not opt?.nodo
            @selectLayer index
            @done()

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    delLayer: (index=@layerIndex) ->

        if @numLayers() == 1 then return

        @do()

        [layer] = @layers.splice index, 1
        layer?.remove()

        @clearSingleLayer()

        @selectLayer index-1
        @done()

    # 00     00  00000000  00000000    0000000   00000000
    # 000   000  000       000   000  000        000
    # 000000000  0000000   0000000    000  0000  0000000
    # 000 0 000  000       000   000  000   000  000
    # 000   000  00000000  000   000   0000000   00000000

    mergeLayer: (index) ->

        if @numLayers() == 1 then return
        if index <= 0 then return

        @do()

        items = @layers[index].children()
        for item in items
            item.toParent @layers[index-1]

        [layer] = @layers.splice index, 1
        layer?.remove()

        @clearSingleLayer()

        @selection.setItems items

        @done()

    clearSingleLayer: ->

        if @layers.length == 1
            for item in @layers[0].children()
                item.toParent item.doc()
            @layers[0].remove()
            @layers = []

    #  0000000  000000000   0000000   000000000  00000000
    # 000          000     000   000     000     000
    # 0000000      000     000000000     000     0000000
    #      000     000     000   000     000     000
    # 0000000      000     000   000     000     00000000

    toggleLayer: (index, state) ->

        if layer = @layerAt index

            @do "layer#{index}#{state}"

            oldValue = layer.data state
            newValue = !oldValue
            layer.data state, newValue

            @applyLayerState index, state

            if state == 'hidden'
                layer.data 'disabled', newValue
                @applyLayerState index, 'disabled'
            if state == 'disabled' and not newValue
                layer.data 'hidden', false
                @applyLayerState index, 'hidden'

            @done()
            @postLayer()

    soloLayer: (index, state) ->

        if layer = @layerAt index

            @do "layer#{index}solo#{state}"

            for layerIndex in [0...@numLayers()]
                @layerAt(layerIndex).data state, index != layerIndex
                @applyLayerState layerIndex, state

                if state == 'hidden'
                    @layerAt(layerIndex).data 'disabled', index != layerIndex
                    @applyLayerState layerIndex, 'disabled'

            if state == 'disabled'
                layer.data 'hidden', false
                @applyLayerState index, 'hidden'

            @activateLayer index

            @done()

    clearState: (state) ->

        @do "layerclear#{state}"

        for layerIndex in [0...@numLayers()]
            @layerAt(layerIndex).data state, false
            @applyLayerState layerIndex, state

            if state == 'disabled'
                @layerAt(layerIndex).data 'hidden', false
                @applyLayerState layerIndex, 'hidden'

        @done()

    applyLayerState: (index, state) ->

        layer = @layerAt index
        value = layer.data state
        switch state
            when 'hidden'
                if value
                    @selection.setItems @selectedItems().filter (item) => @layerForItem(item) != layer
                    layer.hide()
                else layer.show()
            when 'disabled'
                if value
                    @selection.setItems @selectedItems().filter (item) => @layerForItem(item) != layer
                    layer.style 'pointer-events', 'none'
                else layer.style 'pointer-events', 'all'

    #  0000000  000   000   0000000   00000000
    # 000       000 0 000  000   000  000   000
    # 0000000   000000000  000000000  00000000
    #      000  000   000  000   000  000
    # 0000000   00     00  000   000  000

    lowerLayer: (index=@layerIndex) -> @moveLayer index, index-1
    raiseLayer: (index=@layerIndex) -> @moveLayer index, index+1
    moveLayer:  (from, to) ->

        from = @clampLayer from
        to   = @clampLayer to
        if from == to then return

        @do 'layerOrder'

        fromLayer = @layerAt from
        toLayer   = @layerAt to

        @layers.splice from, 1

        if from > to
            toLayer.before fromLayer
            @layers.splice to, 0, fromLayer
        else
            toLayer.after fromLayer
            @layers.splice to, 0, fromLayer

        @activateLayer to
        @done()

    swapLayers: (indexA, indexB) ->

        indexA = @clampLayer indexA
        indexB = @clampLayer indexB
        if indexA == indexB then return

        @do 'layerOrder'

        oldB = indexB
        [indexA, indexB] = [indexB, indexA] if indexA > indexB

        [layerB] = @layers.splice indexB, 1
        [layerA] = @layers.splice indexA, 1

        beforeB = layerB.previous()
        layerA.before layerB
        if beforeB != layerA
            beforeB.after layerA

        @layers.splice indexA, 0, layerB
        @layers.splice indexB, 0, layerA

        @activateLayer oldB
        @done()

    #  0000000  00000000  000      00000000   0000000  000000000
    # 000       000       000      000       000          000
    # 0000000   0000000   000      0000000   000          000
    #      000  000       000      000       000          000
    # 0000000   00000000  0000000  00000000   0000000     000

    selectLayer: (index=@layerIndex) =>

        if layer = @layerAt index

            if layer.data 'hidden'   then @toggleLayer index, 'hidden'
            if layer.data 'disabled' then @toggleLayer index, 'disabled'

            @activateLayer index
            @selection.setItems @activeLayer().children()

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
        
        @kali.browser?.hide()
        
        if file == 'untitled'
            @currentFile = file
            post.emit 'stage', 'load', file:file
            return
        
        @currentFile = slash.resolve file
        
        try
            svg = fs.readFileSync slash.resolve(file), encoding: 'utf8'
        catch e
            log "error:", e
            return

        info = @setSVG svg, parent:@svg
        
        @pushRecent file
        
        post.emit 'stage', 'layer', active:-1, num:0
        
        @loadLayers()
        
        info.file = @currentFile
        
        @postLayer()
        
        @centerSelection()
        @kali.focus()
        
        post.emit 'stage', 'load', info
                
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
                        id:     slash.base file
                        parent: @activeLayer()
                @done()
                
    #  0000000   0000000   000   000  00000000
    # 000       000   000  000   000  000
    # 0000000   000000000   000 000   0000000
    #      000  000   000     000     000
    # 0000000   000   000      0      00000000

    save: (file=@currentFile) ->

        @currentFile = file
        
        if @currentFile == 'untitled'
            return @saveAs()
        
        log 'save @currentFile', @currentFile
        
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
        itemBox = bboxForItems info.items
        boxCenter = boxPos itemBox, 'center'
        mousePos.sub pos window.screenX, window.screenY
        stagePos = @stageForView mousePos
        delta = stagePos.minus boxCenter 
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

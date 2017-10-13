
# 000       0000000   000   000  00000000  00000000
# 000      000   000   000 000   000       000   000
# 000      000000000    00000    0000000   0000000
# 000      000   000     000     000       000   000
# 0000000  000   000     000     00000000  000   000

{ elem, empty, prefs, clamp, post, log, _ } = require 'kxk'

{ uuid } = require '../utils'

LayerList = require './layerlist'
Tool      = require './tool'

class Layer extends Tool

    log: -> #log.apply log, [].slice.call arguments, 0

    constructor: (@kali, cfg) ->

        super @kali, cfg

        @bindStage ['numLayers', 'layerAt', 'activeLayer', 'clampLayer',
            'activateLayer', 'selectLayer', 'lowerLayer', 'raiseLayer',
            'delLayer', 'duplicateLayer', 'mergeLayer', 'splitLayer',
            'postLayer', 'storeLayers', 'restoreLayers', 'layerForItem',
            'createLayer', 'indexOfLayer', 'activateSelectionLayer',
            'toggleLayer', 'applyLayerState', 'loadLayers', 'clearSingleLayer',
            'swapLayers', 'moveLayer', 'soloLayer', 'clearState']

        @stage.layers = []

        @initTitle()
        @initButtons [
            button: true
            tiny:   'spin-minus'
            name:   'decr'
            action: @onDecr
        ,
            text:   '1'
            name:   'layer'
            action: @onLayer
        ,
            button: true
            tiny:   'spin-plus'
            name:   'incr'
            action: @onIncr
        ]
        @initButtons [
            tiny:  'layer-hide'
            name:   'hide'
            action: @onHide
        ,
            tiny:  'layer-disable'
            name:   'disable'
            action: @onDisable
        ]

        post.on 'stage',     @onStage
        post.on 'selection', @onSelection
        
        @stage.layerIndex = 0

    onHide:    => @stage.toggleLayer @stage.layerIndex, 'hidden'
    onDisable: => @stage.toggleLayer @stage.layerIndex, 'disabled'

    onIncr:  => @stage.activateLayer @stage.layerIndex + 1
    onDecr:  => @stage.activateLayer @stage.layerIndex - 1
    onLayer: =>
        if @stage.activeLayer().children().length == @stage.selection.length()
            @stage.selection.clear()
        else
            @stage.selectLayer()
            
    # 000      000   0000000  000000000
    # 000      000  000          000
    # 000      000  0000000      000
    # 000      000       000     000
    # 0000000  000  0000000      000

    toggleList: ->

        if @list?
            @list.toggleDisplay()
        else
            @showList()

    showList: ->

        @list = new LayerList @kali
        @list.show()

    #  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000
    # 000       000       000      000       000          000     000  000   000  0000  000
    # 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000
    #      000  000       000      000       000          000     000  000   000  000  0000
    # 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000

    onSelection: (action, items, item) => @stage.activateSelectionLayer()

    activateSelectionLayer: ->

        return if not @numLayers()
        return if @selection.empty()
        noItems = @selectedItems().filter (item) -> not item?
        @activateLayer _.max @selectedItems().map (item) => @indexOfLayer @layerForItem item

    #  0000000  000000000   0000000    0000000   00000000
    # 000          000     000   000  000        000
    # 0000000      000     000000000  000  0000  0000000
    #      000     000     000   000  000   000  000
    # 0000000      000     000   000   0000000   00000000

    onStage: (action, info) =>

        switch action
            when 'load' 
                for index in [@stage.numLayers()-1..0]
                    layer = @stage.layerAt(index)
                    if not layer.data('hidden') and not layer.data('disabled')
                        @stage.activateLayer index
                        return
            
            when 'layer'
    
                # @log "Layer.onStage layer #{info.active} #{@stage.activeLayer().id()}"
                @button('layer').innerHTML = "#{info.active}"
                
                if not info.num
                    @hideButton 'layer'
                    @hideButton 'incr'
                    @hideButton 'decr'
                else
                    @button('layer').removeAttribute 'style'
    
                    @showButton 'decr', info.active
                    @showButton 'incr', info.active != info.num-1
    
                    @setButtonIcon 'disable', info.disabled and 'layer-disabled' or 'layer-disable'
                    @setButtonIcon 'hide',    info.hidden   and 'layer-hidden'   or 'layer-hide'
    
    # 000       0000000    0000000   0000000          000       0000000   000   000  00000000  00000000    0000000
    # 000      000   000  000   000  000   000        000      000   000   000 000   000       000   000  000
    # 000      000   000  000000000  000   000        000      000000000    00000    0000000   0000000    0000000
    # 000      000   000  000   000  000   000        000      000   000     000     000       000   000       000
    # 0000000   0000000   000   000  0000000          0000000  000   000     000     00000000  000   000  0000000

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

    indexOfLayer: (layer) -> @layers.indexOf layer

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
        items = selected.filter (item) => index == @indexOfLayer @layerForItem item
        if not empty items
            @selection.setItems items
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
        if index < @numLayers()-1
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

module.exports = Layer


# 000       0000000   000   000  00000000  00000000   
# 000      000   000   000 000   000       000   000  
# 000      000000000    00000    0000000   0000000    
# 000      000   000     000     000       000   000  
# 0000000  000   000     000     00000000  000   000  

{ elem, empty, prefs, clamp, post, log, _ } = require 'kxk'

LayerList = require './layerlist'
Tool      = require './tool'

class Layer extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg

        @bindStage ['numLayers', 'layerAt', 'activeLayer', 'clampLayer', 
            'activateLayer', 'selectLayer', 'lowerLayer', 'raiseLayer',
            'delLayer', 'duplicateLayer', 'mergeLayer', 'splitLayer',
            'postLayer', 'storeLayers', 'restoreLayers', 'layerForItem',
            'createLayer', 'indexOfLayer', 'activateSelectionLayer', 
            'toggleLayer', 'applyLayerState', 'loadLayers', 'clearSingleLayer', 
            'swapLayers', 'moveLayer']
        
        @stage.layers = []
        
        @initTitle()
        @initButtons [
            text:   '<'
            name:   'decr'
            action: @onDecr
        ,
            text:   '1'
            name:   'layer'
            action: @onLayer
        ,
            text:   '>'
            name:   'incr'
            action: @onIncr
        ]
        @initButtons [
            text:   '-'
            name:   'lower'
            action: @stage.lowerLayer
        ,
            text:   '+'
            name:   'raise'
            action: @stage.raiseLayer
        ]
        
        post.on 'stage',     @onStage
        post.on 'selection', @onSelection
        
        @stage.activateLayer 0
        
    onIncr:  => @stage.selectLayer @stage.layerIndex + 1
    onDecr:  => @stage.selectLayer @stage.layerIndex - 1
    onLayer: =>
        if @stage.activeLayer().children().length == @stage.selection.length()
            @stage.selection.clear()
        else
            @stage.selectLayer()
            
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (event) =>
        
        super event
        
        @hideChildren()
        
        if @list?
            @list.toggleDisplay()
        else
            @showList()

    # 000      000   0000000  000000000  
    # 000      000  000          000     
    # 000      000  0000000      000     
    # 000      000       000     000     
    # 0000000  000  0000000      000     
    
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
        log 'broken selection!' if not empty noItems
        @activateLayer _.max @selectedItems().map (item) => @indexOfLayer @layerForItem item
            
    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  
    
    onStage: (action, info) =>
        
        if action == 'layer'
            @button('layer').innerHTML = "#{info.active}"
            
            if not info.num
                @button('layer').style.color = 'transparent'
                @button('incr').style.color = 'transparent'
                @button('decr').style.color = 'transparent'
            else
                @button('layer').removeAttribute 'style' 
            
                if not info.active
                    @button('decr').style.color = 'transparent'
                else
                    @button('decr').removeAttribute 'style' 
                    
                if info.active == info.num-1
                    @button('incr').style.color = 'transparent'
                else
                    @button('incr').removeAttribute 'style' 
                    
        if action == 'load'
            @stage.layers = []
            @stage.activateLayer 0            
           
    # 000       0000000   000   000  00000000  00000000   
    # 000      000   000   000 000   000       000   000  
    # 000      000000000    00000    0000000   0000000    
    # 000      000   000     000     000       000   000  
    # 0000000  000   000     000     00000000  000   000  

    loadLayers: ->
        
        gotSvg = false
        gotGrp = false
        
        for item in @items()
            if item.type == 'svg'
                gotSvg = true
            else
                gotGrp = true
                
        return false if not gotSvg        

        if gotGrp
            newLayer = @svg.nested()
            newLayer.id "layer #{@numLayers()}"
            log 'Layer.loadLayers -- non svg stuff on top level:'
            for item in @items()
                if item.type != 'svg'
                    log "Layer.loadLayers -- moving item of type #{item.type} into new layer"
                    newLayer.add item
            
        for item in @items()
            transform = item.transform()
            if not _.isEqual transform.matrix, new SVG.Matrix()
                log 'Layer.loadLayers top level layer with transform?', transform
  
        layerIDs = @items().map (item) -> item.id()
        log 'Layer.loadLayers', layerIDs
        
        @layers = []
        for id in layerIDs
            @layers.push SVG.get id
            @applyLayerState @layers.length-1, 'hidden'
            @applyLayerState @layers.length-1, 'disabled'
            
        @layerIndex = @numLayers()-1
        
        @postLayer()
    
    layerAt: (index) -> 
        index = @clampLayer index
        @numLayers() and @layers[index] or @svg
        
    clampLayer: (index) -> clamp 0, @numLayers()-1, index
    numLayers: -> @layers.length
    postLayer: -> 
        # log "Layer.postLayer num:#{@numLayers()} active:#{@layerIndex}"
        post.emit 'stage', 'layer', active:@layerIndex, num:@layers.length
    
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    layerForItem: (item) ->
        
        parents = item.parents()
        parents[parents.length-2]
        
    indexOfLayer: (layer) -> @layers.indexOf layer
        
    activeLayer: -> @layerAt @layerIndex
    activateLayer: (index) ->
        
        @layerIndex = @clampLayer index
        @postLayer()

    storeLayers: -> 
        
        layerIndex: @layerIndex
        layers:     @layers.map (layer) -> layer.id()
        
    restoreLayers: (state) ->
        
        @layerIndex = state.layerIndex
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
        
        items = @selectedItems().filter (item) -> index == @indexOfLayer @layerForItem item
        if not empty items
            @selection.setItems items
            @createLayer selection:'move', index:index+1
    
    createLayer: (opt) ->
        
        index = opt?.index ? @layerIndex+1 #@numLayers()
        
        # log "createLayer #{index}", opt
        
        @do() if not opt?.nodo
        if not @numLayers()
            layer = @svg.nested()
            layer.id "layer #{@numLayers()}"
            for item in @items()
                item.toParent layer
            @layers.push layer
            
        layer = @svg.nested()
        layer.id "layer #{@numLayers()}"
        # @layers.push layer
        @layers.splice index, 0, layer
        # log 'opt', opt
        switch opt.selection 
            when 'move'
                log 'moveSelection', @selectedItems().length
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
        
        if @numLayers() == 0 then return
        
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
    
        if @numLayers() == 0 then return
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
        
        if @numLayers() == 1
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
                else layer.style 'pointer-events', 'auto'
        
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
        
        @do()
        
        fromLayer = @layerAt from 
        toLayer   = @layerAt to
        
        @layers.splice from, 1
        
        if from > to
            toLayer.before fromLayer
            @layers.splice to, 0, fromLayer
        else 
            toLayer.after fromLayer
            @layers.splice to, 0, fromLayer
                    
        @selectLayer to
        @done()
    
    swapLayers: (indexA, indexB) ->
        
        indexA = @clampLayer indexA
        indexB = @clampLayer indexB
        if indexA == indexB then return
        
        @do()
        
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
        
        @selectLayer oldB
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
            
            if @numLayers()
                @selection.setItems @activeLayer().children()
            else
                @selection.setItems @items()
        
module.exports = Layer


# 000       0000000   000   000  00000000  00000000   
# 000      000   000   000 000   000       000   000  
# 000      000000000    00000    0000000   0000000    
# 000      000   000     000     000       000   000  
# 0000000  000   000     000     00000000  000   000  

{ elem, prefs, clamp, post, log, _ } = require 'kxk'

LayerList = require './layerlist'
Tool      = require './tool'

class Layer extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg

        @bindStage ['numLayers', 'layerAt', 'activeLayer', 'clampLayer', 
            'activateLayer', 'selectLayer', 'lowerLayer', 'raiseLayer',
            'newLayer', 'addLayer', 'delLayer', 'dupLayer', 'createLayer',
            'postLayer', 'storeLayers', 'restoreLayers', 'layerForItem',
            'indexOfLayer', 'activateSelectionLayer', 'toggleLayerState', 'mergeLayer']
        
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
            text:   'add'
            name:   'add'
            action: @stage.addLayer
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
    
    layerAt: (index) -> 
        index = @clampLayer index
        @numLayers() and @layers[index] or @svg
        
    clampLayer: (index) -> clamp 0, @numLayers()-1, index
    numLayers: -> @layers.length
    postLayer: -> post.emit 'stage', 'layer', active:@layerIndex, num:@layers.length
    
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    layerForItem: (item) -> item.parents()[0]
        
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
    
    dupLayer: -> 
        
        @selection.setItems @activeLayer().children()
        @createLayer selection:'copy', index:@layerIndex+1
        
    newLayer: -> @createLayer selection:'keep', index:@layerIndex+1
    addLayer: -> @createLayer selection:'move', index:@layerIndex+1
    
    createLayer: (opt) ->
        
        index = opt?.index ? @numLayers()
        
        log "createLayer #{index}", opt
        
        @do()
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
                log 'layer.createLayer wrong option?', opt
        
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

        if @numLayers() == 1
            for item in @layers[0].children()
                item.toParent item.doc()
            @layers[0].remove()
            @layers = []
        
        @selectLayer index
        @done()

    # 00     00  00000000  00000000    0000000   00000000  
    # 000   000  000       000   000  000        000       
    # 000000000  0000000   0000000    000  0000  0000000   
    # 000 0 000  000       000   000  000   000  000       
    # 000   000  00000000  000   000   0000000   00000000  
    
    mergeLayer: (index) -> 
        log "merge #{index}"
    
        if @numLayers() == 0 then return
        if index <= 0 then return
        
        @do()
        
        for item in @layers[index].children()
            item.toParent @layers[index-1]

        [layer] = @layers.splice index, 1
        layer?.remove()
            
        @done()
    
    toggleLayer: (index, state) -> 
        
        oldState = @layers[index].remember state
        newState = !oldState
        @layers[index].remember state, newState
        log "toggle #{index} #{state} #{oldState} -> #{newState}"
        
    # 000       0000000   000   000  00000000  00000000   
    # 000      000   000  000 0 000  000       000   000  
    # 000      000   000  000000000  0000000   0000000    
    # 000      000   000  000   000  000       000   000  
    # 0000000   0000000   00     00  00000000  000   000  
    
    lowerLayer: (index=@layerIndex) ->
        
        if @numLayers() == 0 then return
        if index == 0 then return
        @do()
        [layer] = @layers.splice index, 1
        layer.backward()
        @layers.splice index-1, 0, layer
        @selectLayer index-1
        @done()
        
    # 00000000    0000000   000   0000000  00000000  
    # 000   000  000   000  000  000       000       
    # 0000000    000000000  000  0000000   0000000   
    # 000   000  000   000  000       000  000       
    # 000   000  000   000  000  0000000   00000000  
    
    raiseLayer: (index=@layerIndex) ->
        
        if @numLayers() == 0 then return
        if index >= @numLayers()-1 then return
        @do()
        [layer] = @layers.splice index, 1
        layer.forward()
        @layers.splice index+1, 0, layer
        @selectLayer index+1        
        @done()
        
    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    selectLayer: (index=@layerIndex) =>
        
        @activateLayer index
        
        if @numLayers()
            @selection.setItems @activeLayer().children()
        else
            @selection.setItems @items()
        
module.exports = Layer

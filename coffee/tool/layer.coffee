
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

        @bindStage ['numLayers', 'activeLayer', 'clampLayer', 'layerAt', 'addLayer', 'delLayer', 'activateLayer', 'postLayer']
        
        @stage.layers = []
        
        @initTitle()
        @initButtons [
            text:   '<'
            name:   'decr'
            action: @onDecr
        ,
            text:   '1'
            name:   'layer'
        ,
            text:   '>'
            name:   'incr'
            action: @onIncr
        ]
        @initButtons [
            text:   'add'
            name:   'add'
            action: @stage.addLayer
        ,
            text:   'del'
            name:   'del'
            action: @stage.delLayer
        ]
        
        post.on 'stage', @onStage
        
        @stage.activateLayer 0
        
    onIncr:  => @selectLayer @stage.layerIndex + 1
    onDecr:  => @selectLayer @stage.layerIndex - 1
    selectLayer: (index) ->
        
        @stage.activateLayer index
        if @stage.numLayers()
            @stage.selection.setItems [@stage.activeLayer()]
        else
            @stage.selection.setItems @stage.items()
    
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
           
    layerAt: (index) -> 
        index = @clampLayer index
        @numLayers() and @layers[index] or @svg
        
    clampLayer: (index) -> clamp 0, @numLayers()-1, index
    numLayers: -> @layers.length
    postLayer: -> post.emit 'stage', 'layer', active:@layerIndex, num:@layers.length
    activeLayer: -> @layerAt @layerIndex
    activateLayer: (index) ->
        
        @layerIndex = @clampLayer index
        log "activateLayer #{index} #{@layerIndex}"
        @postLayer()
    
    addLayer: ->
        
        if not @numLayers()
            layer = @svg.nested()
            layer.id "layer #{@numLayers()}"
            for item in @items()
                item.toParent layer
            @layers.push layer
            
        layer = @svg.nested()
        layer.id "layer #{@numLayers()}"
        @layers.push layer
        log 'addLayer', @numLayers()
        
        for item in @selectedItems()
            item.toParent layer
        
        @activateLayer @numLayers()-1
        
    delLayer: ->
        
        if @numLayers() == 0 then return
        if @numLayers() == 2
            for item in @layers[0].children()
                item.toParent item.doc()
            for item in @layers[1].children()
                item.toParent item.doc()
            @layers[0].remove()
            @layers[1].remove()
            @layers = []
        else
            [layer] = @layers.splice @layerIndex, 1
            log 'delLayer', @layerIndex, layer?
            layer?.remove()
            
        @activateLayer @layerIndex
        
module.exports = Layer

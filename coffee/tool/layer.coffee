###
000       0000000   000   000  00000000  00000000
000      000   000   000 000   000       000   000
000      000000000    00000    0000000   0000000
000      000   000     000     000       000   000
0000000  000   000     000     00000000  000   000
###

{ elem, empty, prefs, clamp, post, log, _ } = require 'kxk'

{ uuid } = require '../utils'

LayerList = require './layerlist'
Tool      = require './tool'

class Layer extends Tool

    constructor: (kali, cfg) ->

        super kali, cfg

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

    #  0000000   000   000   0000000  000000000   0000000    0000000   00000000  
    # 000   000  0000  000  000          000     000   000  000        000       
    # 000   000  000 0 000  0000000      000     000000000  000  0000  0000000   
    # 000   000  000  0000       000     000     000   000  000   000  000       
    #  0000000   000   000  0000000      000     000   000   0000000   00000000  
    
    onStage: (action, info) =>

        switch action
            when 'load' 
                for index in [@stage.numLayers()-1..0]
                    layer = @stage.layerAt(index)
                    if not layer.data('hidden') and not layer.data('disabled')
                        @stage.activateLayer index
                        return
            
            when 'layer'
    
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
                    
module.exports = Layer
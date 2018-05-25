
#  0000000  000   000   0000000   0000000     0000000   000   000  
# 000       000   000  000   000  000   000  000   000  000 0 000  
# 0000000   000000000  000000000  000   000  000   000  000000000  
#      000  000   000  000   000  000   000  000   000  000   000  
# 0000000   000   000  000   000  0000000     0000000   00     00  

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Exporter = require '../exporter'
Tool = require './tool'

class Shadow extends Tool

    constructor: (kali, cfg) ->
        
        super kali, cfg
                
        @initTitle()
        
        @size   = prefs.get 'shadow:size',  10
        @offset = prefs.get 'shadow:offset', 5
                
        @initSpin
            name:   'size'
            min:    0
            max:    100
            reset:  [0,10]
            step:   [1,5,10,25]
            action: @setSize
            value:  @size

        @initSpin
            name:   'offset'
            min:    0
            max:    100
            reset:  [0,10]
            step:   [1,5,10,25]
            action: @setOffset
            value:  @offset
            
    setSize: (size) =>
        
        @size = parseFloat size
        @size = 0 if _.isNaN @size

        prefs.set 'shadow:size', @size
        
        @updateSelected()
                
    setOffset: (offset) =>

        @offset = parseFloat offset
        @offset = 0 if _.isNaN @offset

        prefs.set 'shadow:offset', @offset
        
        @updateSelected()

    updateSelected: ->
        
        if @kali.tool('select').shapeText == 'text'
            items = @stage.selectedLeafItems()
        else
            items = @stage.selectedItems()
        return if empty items

        @filter = new SVG.Filter()
        
        alphaMatrix = [ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0.3, 0]
        
        blur = @filter
            .offset @offset, @offset
            .in @filter.sourceAlpha
            .colorMatrix 'matrix', alphaMatrix
            .gaussianBlur @size, @size
            
        @filter.blend @filter.source, blur            
        @filter.size('300%','300%').move('-100%', '-100%')

        for item in items

            if @offset == 0 == @size
                item.unfilter()
            else
                item.filter @filter
                
        Exporter.cleanFilters @stage.svg
                
module.exports = Shadow

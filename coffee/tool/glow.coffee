###
 0000000   000       0000000   000   000  
000        000      000   000  000 0 000  
000  0000  000      000   000  000000000  
000   000  000      000   000  000   000  
 0000000   0000000   0000000   00     00  
###

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Exporter = require '../exporter'
Tool = require './tool'

class Glow extends Tool

    constructor: (kali, cfg) ->
        
        super kali, cfg
                
        @initTitle()
        
        @size  = prefs.get 'glow:size',  10
        @alpha = prefs.get 'glow:alpha', 0.5
        
        @initSpin
            name:   'size'
            min:    0
            max:    100
            reset:  [0,10]
            step:   [1,5,10,25]
            action: @setSize
            value:  @size

        @initSpin
            name:   'alpha'
            min:    0
            max:    1
            reset:  [0,1]
            speed:  0.01
            step:   [0.01,0.05,0.1,0.5]
            action: @setAlpha
            value:  @alpha
            
    setSize: (size) =>
        
        @size = parseFloat size
        @size = 0 if _.isNaN @size

        prefs.set 'glow:size', @size
        
        @updateSelected()
                
    setAlpha: (alpha) =>
        
        @alpha = parseFloat alpha
        @alpha = 1 if _.isNaN @alpha

        prefs.set 'glow:alpha', @alpha
        
        @updateSelected()

    updateSelected: ->
        
        items = @stage.selectedItems()
        return if empty items
        
        alphaMatrix = [ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, @alpha, 0]
        
        @filter = new SVG.Filter()
        blur = @filter.colorMatrix('matrix', alphaMatrix).gaussianBlur @size, @size
        @filter.blend @filter.source, blur
        @filter.size('300%','300%').move('-100%', '-100%')
        
        for item in items
            
            if @alpha == 0 or @size == 0
                item.unfilter()
            else
                item.filter @filter

        Exporter.cleanFilters @stage.svg
        
module.exports = Glow

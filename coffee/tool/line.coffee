
# 000      000  000   000  00000000  
# 000      000  0000  000  000       
# 000      000  000 0 000  0000000   
# 000      000  000  0000  000       
# 0000000  000  000   000  00000000  

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool = require './tool'

class Line extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @initTitle()
        
        @initSpin
            name:   'width'
            min:    0
            max:    1000
            reset:  [0,1]
            step:   [1,5,10,25]
            action: @setWidth
            value:  prefs.get 'line:width', 1
                    
        post.on 'selection', @onSelection
        
    onSelection: =>
        
        items = @stage.selectedLeafItems()
        return if empty items
        
        width = 0
        for item in items
            width += parseFloat item.style 'stroke-width'
                    
        @setSpinValue 'width', width/items.length
        
    setWidth: (@width) =>
        
        @width = 0 if _.isNaN @width
        prefs.set 'line:width', @width
        
        items = @stage.selectedLeafItems()
        return if empty items
                
        @stage.do 'line'+ itemIDs items
        for item in items
            item.style 'stroke-width': @width
        @stage.done()

        post.emit 'line', 'width', @width
        
module.exports = Line

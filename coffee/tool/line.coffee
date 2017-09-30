
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
            step:   [1,2,5,10]
            action: @setWidth
            
        @initButtons [
            tiny:  'polygon'
            name:   'shapes'
            toggle: prefs.get 'line:shapes', 1
        ,
            tiny:  'text'
            name:   'text'
            toggle: prefs.get 'line:text', 1
        ]
        
        @setWidth prefs.get 'line:width', 1
            
    setWidth: (@width) =>
        
        prefs.set 'width', @width
        
        items = @stage.selectedLeafItems()
        return if empty items
        
        text   = @button('text').toggle
        shapes = @button('shapes').toggle
        
        return if not (text or shapes)
        
        @stage.do 'line'+ itemIDs items
        for item in items
            if (item.type != 'text' or text) and (item.type == 'text' or shapes)
                item.style 'stroke-width': @width
        @stage.done()

        post.emit 'line', 'width', @width
        
module.exports = Line

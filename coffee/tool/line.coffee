
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
        
        @initButtons [
            text:   '-'
            name:   'decr'
            action: @onDecr
        ,
            text:   '1'
            name:   'width'
            action: @onReset
        ,
            text:   '+'
            name:   'incr'
            action: @onIncr
        ]
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
        
    onIncr:  => @setWidth clamp 0, 100, @width + 1
    onDecr:  => @setWidth clamp 0, 100, @width - 1
    onReset: => @setWidth 0
    
    setWidth: (@width) =>
        
        @button('width').innerHTML = "#{parseInt @width}"
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

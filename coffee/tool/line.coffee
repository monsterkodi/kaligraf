
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
        
        @cap   = prefs.get 'line:cap', 'round'
        @width = prefs.get 'line:width', 1
        
        @initSpin
            name:   'width'
            min:    0
            max:    1000
            reset:  [0,1]
            step:   [1,5,10,25]
            action: @setWidth
            value:  @width

        @initButtons [
            tiny: 'line-round'
            name: 'round'
            choice: @cap
            action: => @setCap 'round'
        ,
            tiny: 'line-butt'
            name: 'butt'
            choice: @cap
            action: => @setCap 'butt'
        ,
            tiny: 'line-square'
            name: 'square'
            choice: @cap
            action: => @setCap 'square'
        ]
            
        post.on 'selection', @onSelection
        
    onSelection: =>
        
        items = @stage.selectedLeafItems()
        return if empty items
        
        width = 0
        count = 0
        for item in items
            stroke = parseFloat item.style 'stroke-width'
            if not _.isNaN stroke
                width += stroke
                count++
                
        if count
            @setSpinValue 'width', width/count
        
    setCap: (@cap) ->

        prefs.set 'line:cap', @cap
        
        join = round:'round', butt:'miter', square:'bevel'
        
        items = @stage.selectedLeafItems types:['polygon', 'polyline', 'line', 'rect']
        return if empty items
                
        @stage.do 'linecap'+ itemIDs items
        for item in items
            item.attr 'stroke-linecap': @cap
            item.attr 'stroke-linejoin': join[@cap]
            item.attr 'stroke-miterlimit': 20
        @stage.done()

        post.emit 'line', 'cap', @cap
            
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

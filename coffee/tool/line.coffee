
# 000      000  000   000  00000000  
# 000      000  0000  000  000       
# 000      000  000 0 000  0000000   
# 000      000  000  0000  000       
# 0000000  000  000   000  00000000  

{ stopEvent, elem, prefs, clamp, post, log, _ } = require 'kxk'

Tool = require './tool'

class Line extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @initTitle 'Line'
        
        @initButtons [
            text:   '-'
            action: @onDecr
        ,
            text:   '1'
            name:   'width'
            action: @onReset
        ,
            text:   '+'
            action: @onIncr
        ]
        
        @setWidth prefs.get 'width', 1
        
    onIncr: (event) => stopEvent(event) and @setWidth clamp 0, 100, @width + 1
    onDecr: (event) => stopEvent(event) and @setWidth clamp 0, 100, @width - 1
    onReset: (event) => @setWidth 1
    setWidth: (@width) =>
        @buttonElem('width').innerHTML = "#{parseInt @width}"
        post.emit 'line', 'width', @width
        prefs.set 'width', @width
    
module.exports = Line

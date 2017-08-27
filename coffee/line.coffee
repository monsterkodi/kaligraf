
# 000      000  000   000  00000000  
# 000      000  0000  000  000       
# 000      000  000 0 000  0000000   
# 000      000  000  0000  000       
# 0000000  000  000   000  00000000  

{ stopEvent, elem, clamp, post, log, _ } = require 'kxk'

Tool = require './tool'

class Line extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @title = @element.appendChild elem 'div', class:'title'
        
        @minusPlus @onDecr, @onIncr
        
        @setWidth 1
        
    onIncr: (event) => stopEvent(event) and @setWidth clamp 0, 100, @width + 1
    onDecr: (event) => stopEvent(event) and @setWidth clamp 0, 100, @width - 1
    onClick: (event) => @setWidth 1
    setWidth: (@width) =>
        @title.innerHTML = "#{parseInt @width}"
        post.emit 'line', 'width', @width
    
module.exports = Line
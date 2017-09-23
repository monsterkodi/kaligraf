
#  0000000  00000000  000   000  0000000    
# 000       000       0000  000  000   000  
# 0000000   0000000   000 0 000  000   000  
#      000  000       000  0000  000   000  
# 0000000   00000000  000   000  0000000    

{ log, _ } = require 'kxk'

Tool = require './tool'

class Send extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @initTitle()
        @initButtons [
            icon:   'order-front'
            name:   'front'
            action: => @stage.order 'front'    
        ,
            icon:   'order-back'
            name:   'back'
            action: => @stage.order 'back'
        ]

module.exports = Send


# 00000000    0000000   0000000    0000000    000  000   000   0000000   
# 000   000  000   000  000   000  000   000  000  0000  000  000        
# 00000000   000000000  000   000  000   000  000  000 0 000  000  0000  
# 000        000   000  000   000  000   000  000  000  0000  000   000  
# 000        000   000  0000000    0000000    000  000   000   0000000   

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool = require './tool'

class Padding extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @percent = prefs.get 'padding:percent', 10
        
        @initTitle()
        
        @initSpin
            name:   'percent'
            min:    0
            max:    100
            reset:  [0,10]
            step:   [1,5,10,25]
            action: @setPercent
            value:  @percent
            str:    (value) -> "#{value}%"
            
    setPercent: (@percent) =>
        
        prefs.set 'padding:percent', @percent
        
module.exports = Padding

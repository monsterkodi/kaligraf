
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  
# 000        000   000  000   000  000   000  000  000       0000  000     000     
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     

{ prefs, log, _ } = require 'kxk'

Tool         = require './tool'
GradientList = require './gradientlist'

class Gradient extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @initTitle()
        
        @initButtons [
            name: 'gradient'
            text: 'show'
            action: @toggleList
        ]
        
    # 000      000   0000000  000000000  
    # 000      000  000          000     
    # 000      000  0000000      000     
    # 000      000       000     000     
    # 0000000  000  0000000      000     
    
    toggleList: => 
        
        if @list? 
            @list.toggleDisplay()
        else
            @showList()
    
    showList: ->
        
        @list = new GradientList @kali
        @list.show()
        
module.exports = Gradient

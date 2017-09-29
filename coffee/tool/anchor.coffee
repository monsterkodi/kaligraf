
#  0000000   000   000   0000000  000   000   0000000   00000000   
# 000   000  0000  000  000       000   000  000   000  000   000  
# 000000000  000 0 000  000       000000000  000   000  0000000    
# 000   000  000  0000  000       000   000  000   000  000   000  
# 000   000  000   000   0000000  000   000   0000000   000   000  

{ prefs, post, first, last, empty, log, _ } = require 'kxk'

Tool = require './tool'

class Anchor extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @anchor = prefs.get 'text:anchor', 'middle'
        
        @initTitle()
        
        @initButtons [
            action: => @setAnchor 'start'
            name:   'start'
            tiny:   'anchor-start'
            choice: @anchor
        ,
            action: => @setAnchor 'middle'
            name:   'middle'
            tiny:   'anchor-middle'
            choice: @anchor
        ,
            action: => @setAnchor 'end'
            name:   'end'
            tiny:   'anchor-end'
            choice: @anchor
        ]
                
    setAnchor: (@anchor) => 
    
        prefs.set 'text:anchor', @anchor
        
        textItems = @stage.selectedTextItems()
        return if empty textItems
        
        @stage.do()
        
        for item in textItems
            item.font 'anchor', @anchor
            
        @stage.done()
    
module.exports = Anchor

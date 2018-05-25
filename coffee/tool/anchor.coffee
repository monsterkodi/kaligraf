
#  0000000   000   000   0000000  000   000   0000000   00000000   
# 000   000  0000  000  000       000   000  000   000  000   000  
# 000000000  000 0 000  000       000000000  000   000  0000000    
# 000   000  000  0000  000       000   000  000   000  000   000  
# 000   000  000   000   0000000  000   000   0000000   000   000  

{ prefs, post, first, last, empty, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool = require './tool'

class Anchor extends Tool
        
    constructor: (kali, cfg) ->
        
        super kali, cfg
                
        @anchor  = prefs.get 'text:anchor', 'middle'
        @leading = prefs.get 'text:leading', 1.2
        
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
        
        @initSpin 
            name:   'leading'
            value:  @leading
            min:    0.2
            max:    2.0
            step:   [0.01, 0.05, 0.1, 0.5]
            reset:  1.2
            action: @onLeading
            
        post.on 'selection', @onSelection
           
    onSelection: =>    
        
        textItems = @stage.selectedTextItems()
        return if empty textItems
        
        anchor = null
        for item in textItems
            if anchor == null
                anchor = item.font 'anchor'
            else if anchor != item.font 'anchor'
                anchor = null
                break
        if anchor
            @setToggle anchor
    
        leading = 0
        for item in textItems
            leading += item.leading().value
        leading /= textItems.length

        @setSpinValue 'leading', leading
            
    setAnchor: (@anchor) => 
    
        prefs.set 'text:anchor', @anchor
        
        textItems = @stage.selectedTextItems()
        return if empty textItems
        
        @stage.do 'anchor' + itemIDs textItems
        
        for item in textItems
            item.font 'anchor', @anchor
          
        @stage.selection.update()
        @stage.resizer.update()
        @stage.done()
    
    onLeading: =>
        
        spin = @getSpin 'leading'
        @leading = spin.value
        
        prefs.set 'text:leading', @leading
        
        textItems = @stage.selectedTextItems()
        return if empty textItems
        
        @stage.do 'leading' + itemIDs textItems
        
        for item in textItems
            item.font 'leading', @leading

        @stage.selection.update()
        @stage.resizer.update()            
        @stage.done()
        
module.exports = Anchor

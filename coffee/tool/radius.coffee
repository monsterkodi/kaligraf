###
00000000    0000000   0000000    000  000   000   0000000  
000   000  000   000  000   000  000  000   000  000       
0000000    000000000  000   000  000  000   000  0000000   
000   000  000   000  000   000  000  000   000       000  
000   000  000   000  0000000    000   0000000   0000000   
###

{ prefs, post, first, last, empty, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool = require './tool'

class Radius extends Tool
        
    constructor: (kali, cfg) ->
        
        super kali, cfg
                
        @radius = prefs.get 'border:radius', 0
        
        @initTitle()
        
        @initSpin 
            name:   'radius'
            value:  @radius
            min:    0
            max:    100
            step:   [1, 5, 10, 25]
            reset:  0
            action: @onRadius
            
        post.on 'selection', @onSelection
           
    onSelection: =>    
        
        items = @rectItems()
        return if empty items
        
        radius = 0
        for item in items
            radius += parseFloat item.node.getAttribute 'rx'
        radius /= items.length

        @setSpinValue 'radius', radius

    rectItems: =>
        
        items = @stage.selectedLeafItems()
        items = items.filter (item) -> item.type == 'rect'
        items
        
    onRadius: =>
        
        spin = @getSpin 'radius'
        @radius = spin.value
        
        prefs.set 'border:radius', @radius
        
        items = @rectItems()
        return if empty items
                
        @stage.do 'radius'+ itemIDs items
        for item in items
            item.radius @radius
        @stage.done()
        
module.exports = Radius

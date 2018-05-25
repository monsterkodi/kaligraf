###
00000000    0000000   000000000  000000000  00000000  00000000   000   000  
000   000  000   000     000        000     000       000   000  0000  000  
00000000   000000000     000        000     0000000   0000000    000 0 000  
000        000   000     000        000     000       000   000  000  0000  
000        000   000     000        000     00000000  000   000  000   000  
###

{ post, first, last, prefs, empty, log, _ } = require 'kxk'

{ uuid } = require '../utils'

Tool = require './tool'

class Pattern extends Tool
        
    constructor: (kali, cfg) ->
        
        super kali, cfg
        
        @bindStage ['pattern', 'unpattern']
        
        @initTitle()
        
        @initButtons [
            action: @onPattern
            name:   'pattern'
            icon:   'pattern'
        ,
            action: @onUnpattern
            name:   'unpattern'
            icon:   'unpattern'
        ]
                
    onUnpattern: => @stage.unpattern()
    onPattern:   => @stage.pattern()

    execute: -> 

    #  0000000  000000000   0000000    0000000   00000000    
    # 000          000     000   000  000        000         
    # 0000000      000     000000000  000  0000  0000000     
    #      000     000     000   000  000   000  000         
    # 0000000      000     000   000   0000000   00000000    
    
    pattern: ->

        sortedItems = @sortedSelectedItems()
        
        if sortedItems.length > 1
            
            @do()
            pattern = @svg.pattern()
            last(sortedItems).after pattern
            uuid pattern
            
            for item in sortedItems
               pattern.add item
               
            @selection.setItems [pattern]
            @done()
            post.emit 'pattern', 'pattern'
        
    # 000   000  000   000  00000000    0000000   000000000  000000000  00000000  00000000   000   000  
    # 000   000  0000  000  000   000  000   000     000        000     000       000   000  0000  000  
    # 000   000  000 0 000  00000000   000000000     000        000     0000000   0000000    000 0 000  
    # 000   000  000  0000  000        000   000     000        000     000       000   000  000  0000  
    #  0000000   000   000  000        000   000     000        000     00000000  000   000  000   000  
    
    unpattern: ->

        patterns = @selectedItems type:'pattern'
        if not empty patterns
            @do()
            oldItems = _.clone @items()
            
            for pattern in patterns
                for child in pattern.children()
                    child.toParent pattern.parent()
                    pattern.before child
                pattern.remove()
                
            @selection.clear()
            @selection.setItems @items().filter (item) -> item not in oldItems
            @done()  
            post.emit 'pattern', 'unpattern'
    
module.exports = Pattern

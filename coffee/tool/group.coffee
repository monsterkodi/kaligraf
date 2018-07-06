###
 0000000   00000000    0000000   000   000  00000000 
000        000   000  000   000  000   000  000   000
000  0000  0000000    000   000  000   000  00000000 
000   000  000   000  000   000  000   000  000      
 0000000   000   000   0000000    0000000   000      
###

{ post, first, last, prefs, empty, log, _ } = require 'kxk'

{ uuid } = require '../utils'

Tool = require './tool'

class Group extends Tool
        
    constructor: (kali, cfg) ->
        
        super kali, cfg
        
        @bindStage ['group', 'ungroup']
        
        @initTitle()
        
        @initButtons [
            action: @onGroup
            name:   'group'
            icon:   'group'
        ,
            action: @onUngroup
            name:   'ungroup'
            icon:   'ungroup'
        ]
                
    onUngroup: => @stage.ungroup()
    onGroup:   => @stage.group()

    execute: -> 

    #  0000000  000000000   0000000    0000000   00000000    
    # 000          000     000   000  000        000         
    # 0000000      000     000000000  000  0000  0000000     
    #      000     000     000   000  000   000  000         
    # 0000000      000     000   000   0000000   00000000    
        
    #  0000000   00000000    0000000   000   000  00000000   
    # 000        000   000  000   000  000   000  000   000  
    # 000  0000  0000000    000   000  000   000  00000000   
    # 000   000  000   000  000   000  000   000  000        
    #  0000000   000   000   0000000    0000000   000        
    
    group: ->

        sortedItems = @sortedSelectedItems()
        
        if sortedItems.length > 1
            
            @do()
            group = @svg.group()
            last(sortedItems).after group
            uuid group
            
            for item in sortedItems
               group.add item
               
            @selection.setItems [group]
            @done()
            post.emit 'group', 'group'
        
    # 000   000  000   000   0000000   00000000    0000000   000   000  00000000   
    # 000   000  0000  000  000        000   000  000   000  000   000  000   000  
    # 000   000  000 0 000  000  0000  0000000    000   000  000   000  00000000   
    # 000   000  000  0000  000   000  000   000  000   000  000   000  000        
    #  0000000   000   000   0000000   000   000   0000000    0000000   000        
    
    ungroup: ->
        groups = @selectedItems type:'g'
        if not empty groups
            @do()
            newItems = @selectedItems noType:'g'
            
            for group in groups
                groupParent = group.parent()
                for child in group.children()
                    child.toParent groupParent
                    group.before child
                    newItems.push child
                group.remove()
                
            @selection.clear()
            @selection.setItems newItems
            @done()  
            post.emit 'group', 'ungroup'
    
module.exports = Group

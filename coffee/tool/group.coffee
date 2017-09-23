
#  0000000   00000000    0000000   000   000  00000000 
# 000        000   000  000   000  000   000  000   000
# 000  0000  0000000    000   000  000   000  00000000 
# 000   000  000   000  000   000  000   000  000      
#  0000000   000   000   0000000    0000000   000      

{ post, first, last, prefs, empty, log, _ } = require 'kxk'

{ uuid } = require '../utils'

Tool = require './tool'

class Group extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @stage.group   = Group.group
        @stage.ungroup = Group.ungroup
        @stage.ids     = Group.ids
        
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
    
    @group: ->

        sortedItems = @sortedSelectedItems()
        
        if sortedItems.length > 1
            
            @do()
            group = @svg.group()
            group.after last sortedItems
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
    
    @ungroup: ->

        groups = @selectedItems type:'g'
        if not empty groups
            @do()
            oldItems = _.clone @items()
            
            for group in groups
                for child in group.children()
                    child.toParent group.parent()
                    child.before group
                group.remove()
                
            @selection.clear()
            @selection.setItems @items().filter (item) -> item not in oldItems
            @done()  
            post.emit 'group', 'ungroup'
    
module.exports = Group

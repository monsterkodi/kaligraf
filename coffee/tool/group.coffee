
#  0000000   00000000    0000000   000   000  00000000 
# 000        000   000  000   000  000   000  000   000
# 000  0000  0000000    000   000  000   000  00000000 
# 000   000  000   000  000   000  000   000  000      
#  0000000   000   000   0000000    0000000   000      

{ prefs, empty, log, _ } = require 'kxk'

Tool = require './tool'

class Group extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @stage = @kali.stage
        
        @stage.group   = Group.group
        @stage.ungroup = Group.ungroup
        @stage.ids     = Group.ids
        
        @initTitle 'Group'
        
        @initButtons [
            action: @onGroup
            name:   'group'
            svg:    'rect'
        ,
            action: @onUngroup
            name:   'ungroup'
            svg:    'circle'
        ]
        
        @initButtons [
            text:   'IDs'
            name:   'ids'
            action: @onIDs
            toggle: prefs.get 'stage:ids', false
        ]
        
    onUngroup: => @stage.ungroup()
    onGroup:   => @stage.group()
    onIDs:     => @stage.ids()

    execute: -> log 'group execute'

    #  0000000  000000000   0000000    0000000   00000000    
    # 000          000     000   000  000        000         
    # 0000000      000     000000000  000  0000  0000000     
    #      000     000     000   000  000   000  000         
    # 0000000      000     000   000   0000000   00000000    
    
    @group: ->

        sortedItems = @sortedSelectedItems()
        if not empty sortedItems
            @do()
            group = @svg.group()
            
            for item in sortedItems
               group.add item
               
            @selection.setItems [group]
            @done()
        
    @ungroup: ->

        groups = @selectedItems type:'g'
        if not empty groups
            @do()
            oldItems = _.clone @items()
            
            for group in groups 
                group.ungroup()
                
            @selection.clear()
            @selection.setItems @items().filter (item) -> item not in oldItems
            @done()
        
    @ids: -> 
    
        ids = prefs.get 'stage:ids', false
        ids = !ids
        prefs.set 'stage:ids', ids
        
        @selection.showIDs ids
    
module.exports = Group

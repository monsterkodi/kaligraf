
#  0000000   00000000    0000000   000   000  00000000 
# 000        000   000  000   000  000   000  000   000
# 000  0000  0000000    000   000  000   000  00000000 
# 000   000  000   000  000   000  000   000  000      
#  0000000   000   000   0000000    0000000   000      

{ prefs, log, _ } = require 'kxk'

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
            text:   'G'
            action: @onGroup
        ,
            text:   'U'
            action: @onUngroup
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
    
    @ungroup: ->
        
        @do()
        oldItems = _.clone @items()
        groups = @selectedItems type:'g'
        for group in groups 
            group.ungroup()
            
        @selection.clear()
        @selection.setItems @items().filter (item) -> item not in oldItems
        @done()
        
    @group: ->
        
        @do()
        group = @svg.group()
        for item in @sortedSelectedItems()
           group.add item
           
        @selection.setItems [group]
        @done()
        
    @ids: -> log 'ids'
    
module.exports = Group

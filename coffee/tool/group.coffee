
#  0000000   00000000    0000000   000   000  00000000 
# 000        000   000  000   000  000   000  000   000
# 000  0000  0000000    000   000  000   000  00000000 
# 000   000  000   000  000   000  000   000  000      
#  0000000   000   000   0000000    0000000   000      

{ log, _ } = require 'kxk'

Tool = require './tool'

class Group extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @stage = @kali.stage
        
        @stage.group   = Group.group
        @stage.ungroup = Group.ungroup
        
        @initTitle 'Group'
        
        @initButtons [
            text:   'G'
            action: @onGroup
        ,
            text:   'U'
            action: @onUngroup
        ]
        
    onUngroup: (event) => @stage.ungroup()
    onGroup:   (event) => @stage.group()

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
    
module.exports = Group

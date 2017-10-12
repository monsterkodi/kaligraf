
# 00     00   0000000    0000000  000   000  
# 000   000  000   000  000       000  000   
# 000000000  000000000  0000000   0000000    
# 000 0 000  000   000       000  000  000   
# 000   000  000   000  0000000   000   000  

{ post, first, last, prefs, empty, valid, log, _ } = require 'kxk'

{ uuid, itemIDs } = require '../utils'

Tool = require './tool'

class Mask extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @bindStage ['mask', 'unmask']
        
        @initTitle()
        
        @initButtons [
            action: @onMask
            name:   'mask'
            icon:   'mask-mask'
        ,
            action: @onUnmask
            name:   'unmask'
            icon:   'mask-unmask'
        ]
                
    onMask:   => @stage.mask()
    onUnmask: => @stage.unmask()

    execute: -> 

    #  0000000  000000000   0000000    0000000   00000000    
    # 000          000     000   000  000        000         
    # 0000000      000     000000000  000  0000  0000000     
    #      000     000     000   000  000   000  000         
    # 0000000      000     000   000   0000000   00000000    
    
    mask: ->

        sortedItems = @sortedSelectedItems noTypes:['clipPath']
        
        if valid sortedItems
            
            @do()
        
            maskItems = @filterItems sortedItems, type:'mask'
            if valid maskItems
                
                if maskItems.length > 1
                    log 'handle multiple masks!'
                    
                mask = first maskItems
                
                for item in @filterItems(sortedItems, noType:'mask')
                    
                    item.maskWith mask
                
            else
            
                @do()
                mask = @svg.mask()
                last(sortedItems).after mask
                uuid mask
                
                for item in sortedItems
                   mask.add item
                   
                @selection.setItems [mask]
                
                post.emit 'mask', 'mask'
                
            @done()
        
    # 000   000  000   000  00     00   0000000    0000000  000   000  
    # 000   000  0000  000  000   000  000   000  000       000  000   
    # 000   000  000 0 000  000000000  000000000  0000000   0000000    
    # 000   000  000  0000  000 0 000  000   000       000  000  000   
    #  0000000   000   000  000   000  000   000  0000000   000   000  
    
    unmask: ->

        sortedItems = @sortedSelectedItems noTypes:['clipPath']
        
        if valid sortedItems
            
            @do()

            maskItems   = @filterItems sortedItems, type:'mask'
            noMaskItems = @filterItems sortedItems, noType:'mask'
            maskedItems = noMaskItems.filter (item) -> item.masker? or item.attr 'mask'

            if valid maskedItems
                
                for item in maskedItems
                    
                    item.unmask()
                
            else      
                
                oldItems = _.clone @items()
                
                for mask in maskItems
                    for child in mask.children()
                        child.toParent mask.parent()
                        mask.before child
                    mask.remove()
                    
                @selection.clear()
                @selection.setItems @items().filter (item) -> item not in oldItems
                post.emit 'mask', 'unmask'
            
            @done()  
    
module.exports = Mask

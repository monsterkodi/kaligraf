
#  0000000  000      000  00000000   
# 000       000      000  000   000  
# 000       000      000  00000000   
# 000       000      000  000        
#  0000000  0000000  000  000        

{ post, first, last, prefs, empty, valid, log, _ } = require 'kxk'

{ uuid } = require '../utils'

Tool = require './tool'

class Clip extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @bindStage ['clip', 'unclip']
        
        @initTitle()
        
        @initButtons [
            action: @onClip
            name:   'clip'
            icon:   'clip-clip'
        ,
            action: @onUnclip
            name:   'unclip'
            icon:   'clip-unclip'
        ]
                
    onUnclip: => @stage.unclip()
    onClip:   => @stage.clip()

    execute: -> 

    #  0000000  000000000   0000000    0000000   00000000    
    # 000          000     000   000  000        000         
    # 0000000      000     000000000  000  0000  0000000     
    #      000     000     000   000  000   000  000         
    # 0000000      000     000   000   0000000   00000000    
    
    clip: ->

        sortedItems = @sortedSelectedItems noTypes:['mask']
        
        if valid sortedItems
            
            @do()

            clipItems = @filterItems sortedItems, type:'clipPath'
            if valid clipItems
                
                if clipItems.length > 1
                    log 'handle multiple clips!'
                    
                clip = first clipItems
                
                for item in @filterItems(sortedItems, noType:'clipPath')
                    
                    item.clipWith clip
            
            else
                
                clip = @svg.clip()
                last(sortedItems).after clip
                uuid clip
                
                for item in sortedItems
                   clip.add item
                   
                @selection.setItems [clip]
                post.emit 'clip', 'clip'
            
            @done()
        
    # 000   000  000   000   0000000  000      000  00000000   
    # 000   000  0000  000  000       000      000  000   000  
    # 000   000  000 0 000  000       000      000  00000000   
    # 000   000  000  0000  000       000      000  000        
    #  0000000   000   000   0000000  0000000  000  000        
    
    unclip: ->

        sortedItems = @sortedSelectedItems noTypes:['mask']
        
        if valid sortedItems
            
            @do()
            
            clipItems = @filterItems sortedItems, type:'clipPath'
            noClipItems = @filterItems sortedItems, noType:'clipPath'
            
            if valid noClipItems
                
                for item in noClipItems
                    
                    item.unclip()
                
            else
                oldItems = _.clone @items()
                
                for clip in clipItems
                    for child in clip.children()
                        child.toParent clip.parent()
                        clip.before child
                    clip.remove()
                    
                @selection.clear()
                @selection.setItems @items().filter (item) -> item not in oldItems
                post.emit 'clip', 'unclip'
                
            @done()  
    
module.exports = Clip

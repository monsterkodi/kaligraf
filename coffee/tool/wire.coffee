
# 000   000  000  00000000   00000000  
# 000 0 000  000  000   000  000       
# 000000000  000  0000000    0000000   
# 000   000  000  000   000  000       
# 00     00  000  000   000  00000000  

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs, contrastColor } = require '../utils'

Tool = require './tool'

class Wire extends Tool

    constructor: (kali, cfg) ->
        
        super kali, cfg
                
        @initTitle()
        
        @initButtons [
            icon:   'wire-solid'
            name:   'unwire'
            action: @onUnwire
        ,
            icon:   'wire-wire'
            name:   'wire'
            action: @onWire
        ]
        
        post.on 'stage', @onStage
        
    onStage: (action) =>
        
        switch action 
            when 'willSave' then @unwire @stage.treeItems()
            when 'viewbox'  
                set = @stage.svg.select '.wired'
                width = 1/@stage.zoom
                set.each (index) -> if @type != 'text' then @style 'stroke-width', width
        
    onWire: =>
        
        items = @stage.selectedLeafOrAllItems()
        return if empty items
        
        @stage.do 'wire'+itemIDs items
        
        color = contrastColor(@stage.color).toHex()

        for item in items
            
            for style in ['fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width']
                if not item.data('wire'+style)? and item.style(style)?
                    item.data 'wire'+style, item.style(style)
                # else
                    # log "don't store #{style}", item.data(style), item.style style
                    
            if item.type == 'text'
                item.style 
                    'fill':             color
                    'stroke-opacity':   0
                    'fill-opacity':     1
            else
                item.style 
                    'stroke':           color
                    'stroke-width':     1/@stage.zoom
                    'stroke-opacity':   1
                    'fill-opacity':     0

            item.node.classList.add 'wired'
                
        @stage.done()
                
    onUnwire: => 
        
        items = @stage.selectedLeafOrAllItems()
        return if empty items
        
        @stage.do 'wire'+itemIDs items
        @unwire items                        
        @stage.done()
        
    unwire: (items) ->
        
        for item in items
            
            item.node.classList.remove 'wired'
            
            for style in ['fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width']
                if item.data('wire'+style)?
                    item.style style, item.data 'wire'+style
                    item.data  'wire'+style, null
                    
module.exports = Wire

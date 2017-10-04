
# 000   000  000  00000000   00000000  
# 000 0 000  000  000   000  000       
# 000000000  000  0000000    0000000   
# 000   000  000  000   000  000       
# 00     00  000  000   000  00000000  

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs, contrastColor } = require '../utils'

Tool = require './tool'

class Wire extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
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
        
        if action == 'willSave'
            log 'unwire willSave'
            @unwire @stage.treeItems()
        
    onWire: =>
        
        items = @stage.selectedLeafOrAllItems()
        return if empty items
        
        @stage.do 'wire'+itemIDs items
        
        color = contrastColor(@stage.color).toHex()

        for item in items
            
            for style in ['fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width']
                if not item.data('wire'+style)? and item.style(style)?
                    item.data 'wire'+style, item.style(style)
                else
                    log "don't store #{style}", item.data(style), item.style style
                    
            if item.type == 'text'
                item.style 
                    'fill':             color
                    'stroke-opacity':   0
                    'fill-opacity':     1
            else
                item.style 
                    'stroke':           color
                    'stroke-width':     1
                    'stroke-opacity':   1
                    'fill-opacity':     0
                                        
        @stage.done()
                
    onUnwire: => 
        
        items = @stage.selectedLeafOrAllItems()
        return if empty items
        
        @stage.do 'wire'+itemIDs items
        @unwire items                        
        @stage.done()
        
    unwire: (items) ->
        
        for item in items
            
            for style in ['fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width']
                if item.data('wire'+style)?
                    item.style style, item.data 'wire'+style
                    item.data  'wire'+style, null
                    
module.exports = Wire

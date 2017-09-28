
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
            tiny:   'wire-solid'
            name:   'solid'
            action: @onSolid
        ,
            tiny:   'wire-wire'
            name:   'wire'
            action: @onWire
        ]
        @initButtons [
            tiny:   'polygon'
            name:   'shapes'
            toggle: prefs.get 'wire:shapes', 1
            action: => prefs.set 'wire:shapes', @button('shapes').toggle
        ,
            tiny:   'text'
            name:   'text'
            toggle: prefs.get 'wire:text', 1
            action: => prefs.set 'wire:text', @button('text').toggle
        ]
        
    onWire: => 
        
        items = @stage.selectedLeafItems()
        items = @stage.treeItems() if empty items
        
        text   = @button('text').toggle
        shapes = @button('shapes').toggle
        
        return if not (text or shapes)
        
        @stage.do()
        
        color = contrastColor(@stage.color).toHex()

        for item in items
            
            if (item.type != 'text' or text) and (item.type == 'text' or shapes)
                
                for style in ['stroke-width', 'stroke', 'fill-opacity', 'stroke-opacity']
                    if not item.data(style)?
                        item.data style, item.style(style) 
                    
                item.style 
                    'stroke':           color
                    'stroke-width':     1  
                    'stroke-opacity':   1
                    'fill-opacity':     0
                    
            if item.type == 'text' and not text
                
                for style in ['stroke', 'fill']
                    item.data style, item.style(style) if not item.data(style)?
                    
                item.style 
                    'stroke': color
                    'fill':   color
                    
        @stage.done()
                
    onSolid: => 
        
        items = @stage.selectedLeafItems()
        items = @stage.treeItems() if empty items
        
        text   = @button('text').toggle
        shapes = @button('shapes').toggle
        
        return if not (text or shapes)
        
        @stage.do()
        
        for item in items
            
            if (item.type != 'text' or text) and (item.type == 'text' or shapes)
                
                for style in ['stroke-width', 'stroke', 'fill-opacity', 'stroke-opacity']
                    if item.data(style)?
                        item.style style, item.data style
                        item.data  style, null

            if item.type == 'text' and not text
                
                for style in ['stroke', 'fill']
                    if item.data(style)?
                        item.style style, item.data style
                        item.data  style, null
                        
        @stage.done()
                    
module.exports = Wire

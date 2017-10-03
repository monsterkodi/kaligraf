
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
            name:   'solid'
            action: @onSolid
        ,
            small:  'wire-wire'
            name:   'wire'
            action: @onWire
        ]
        
    onWire: => 
        
        items = @stage.selectedLeafItems()
        
        return if empty items
        
        @stage.do()
        
        color = contrastColor(@stage.color).toHex()

        for item in items
            
            for style in ['stroke-width', 'stroke', 'fill', 'fill-opacity', 'stroke-opacity']
                if not item.data(style)?
                    item.data style, item.style(style) 
            
            if @kali.tool('select').fillStroke.includes 'stroke'
                item.style 
                    'stroke':           color
                    'stroke-width':     1
                    'stroke-opacity':   1
                    
            if @kali.tool('select').fillStroke.includes 'fill'                
                item.style
                    'fill':             color
                    'fill-opacity':     0
                                        
        @stage.done()
                
    onSolid: => 
        
        items = @stage.selectedLeafItems()
        
        return if empty items
        
        @stage.do()
        
        for item in items
            
            for style in ['stroke-width', 'stroke', 'fill', 'fill-opacity', 'stroke-opacity']
                if item.data(style)?
                    item.style style, item.data style
                    item.data  style, null
                        
        @stage.done()
                    
module.exports = Wire

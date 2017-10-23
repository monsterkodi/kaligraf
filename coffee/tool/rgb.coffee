###
00000000    0000000   0000000    
000   000  000        000   000  
0000000    000  0000  0000000    
000   000  000   000  000   000  
000   000   0000000   0000000    
###

{ prefs, clamp, empty, first, post, pos, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool = require './tool'

class RGB extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @initSpin
            triple: 'R'
            name:   'red'
            min:    0
            max:    255
            reset:  [0,255]
            step:   [1,5,10,25]
            action: @postColor
            value:  255
            str: (value) -> parseInt value

        @initSpin
            triple: 'G'
            name:   'green'
            min:    0
            max:    255
            reset:  [0,255]
            step:   [1,5,10,25]
            action: @postColor
            value:  255
            str: (value) -> parseInt value

        @initSpin
            triple: 'B'
            name:   'blue'
            min:    0
            max:    255
            reset:  [0,255]
            step:   [1,5,10,25]
            action: @postColor
            value:  255
            str: (value) -> parseInt value
            
        post.on 'selection', @update
        post.on 'edit',      @update
        @update()

    # 00000000    0000000    0000000  000000000  
    # 000   000  000   000  000          000     
    # 00000000   000   000  0000000      000     
    # 000        000   000       000     000     
    # 000         0000000   0000000      000     
    
    postColor: => 
        color = new SVG.Color r:@getSpin('red').value, g:@getSpin('green').value, b:@getSpin('blue').value
        if @kali.tool('select').fillStroke.includes 'stroke'
            post.emit 'color', 'stroke', prop:'color', color: color, alpha: @kali.tool('stroke').alpha
        if @kali.tool('select').fillStroke.includes 'fill'
            post.emit 'color', 'fill', prop:'color', color: color, alpha: @kali.tool('fill').alpha
        
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
                
    update: =>
        
        items = @stage.selectedLeafItems()
        if empty items
            @disableSpin 'red'
            @disableSpin 'green'
            @disableSpin 'blue'
        else 
            @enableSpin 'red'
            @enableSpin 'green'
            @enableSpin 'blue'
            color = @selectionColor()
            @setSpinValue 'red',   color.r
            @setSpinValue 'green', color.g
            @setSpinValue 'blue',  color.b
                                
    selectionColor: ->
        
        items = @stage.selectedLeafItems()
        
        return new SVG.Color() if empty items
        
        r = g = b = n = 0
        
        if @kali.tool('select').fillStroke.includes 'stroke'
            for item in items 
                color = item.style 'stroke'
                if not color.startsWith 'url'
                    c = new SVG.Color color
                    r += c.r
                    g += c.g
                    b += c.b
                    n++
                    
        if @kali.tool('select').fillStroke.includes 'fill'
            for item in items 
                color = item.style 'fill'
                if not color.startsWith 'url'
                    c = new SVG.Color color
                    r += c.r
                    g += c.g
                    b += c.b
                    n++
            
        new SVG.Color r:r/n, g:g/n, b:b/n 
    
module.exports = RGB

###
000   000   0000000  000   000  
000   000  000       000   000  
000000000  0000000    000 000   
000   000       000     000     
000   000  0000000       0      
###

{ prefs, clamp, empty, first, post, pos, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

chroma = require 'chroma-js'
Tool   = require './tool'

class HSV extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @initSpin
            triple: 'H'
            name:   'hue'
            min:    0
            max:    360
            reset:  [0,120,240]
            step:   [1, 6, 12, 26]
            action: @postColor            
            value:  0
            str: (value) -> if _.isNaN(value) then ' ' else parseInt value

        @initSpin
            triple: 'S'
            name:   'saturation'
            speed:  0.01
            min:    0
            max:    1
            reset:  [0,0.5,1]
            step:   [0.01, 0.05, 0.1, 0.2]
            action: @postColor
            value:  1
            str: (value) -> if _.isNaN(value) then ' ' else parseInt value * 100

        @initSpin
            triple: 'V'
            name:   'value'
            speed:  0.01
            min:    0
            max:    1
            reset:  [0,0.5,1]
            step:   [0.01, 0.05, 0.1, 0.2]
            action: @postColor
            value:  1
            str: (value) -> if _.isNaN(value) then ' ' else parseInt value * 100
            
        post.on 'selection', @update
        post.on 'edit',      @update
        post.on 'color',     @onColor
        @update()


    # 00000000    0000000    0000000  000000000  
    # 000   000  000   000  000          000     
    # 00000000   000   000  0000000      000     
    # 000        000   000       000     000     
    # 000         0000000   0000000      000     
    
    postColor: => 
        
        rgb = chroma(@getSpin('hue').value, @getSpin('saturation').value, @getSpin('value').value, 'hsv').rgb()
        color = new SVG.Color r:rgb[0], g:rgb[1], b:rgb[2]
        if @kali.tool('select').fillStroke.includes 'stroke'
            post.emit 'color', 'stroke', prop:'color', color: color, alpha: @kali.tool('stroke').alpha
        if @kali.tool('select').fillStroke.includes 'fill'
            post.emit 'color', 'fill', prop:'color', color: color, alpha: @kali.tool('fill').alpha
        
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    onColor: (action, info) =>
    
        if action in ['fill', 'stroke'] 
            color = info.color
            if color.r? and color.g? and color.b?
                @setHSV chroma(color.r, color.g, color.b).hsv() 
                
    update: =>
        
        items = @stage.selectedLeafItems()
        if empty items
            @disableSpin 'hue'
            @disableSpin 'saturation'
            @disableSpin 'value'
        else 
            @setHSV @selectionHSV()

    setHSV: (hsv) ->
        
        @enableSpin 'hue'
        @enableSpin 'saturation'
        @enableSpin 'value'
        
        @setSpinValue 'hue',        hsv[0]
        @setSpinValue 'saturation', hsv[1]
        @setSpinValue 'value',      hsv[2]
        
    selectionHSV: ->
        
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

        chroma(r/n, g/n, b/n).hsv()
    
module.exports = HSV

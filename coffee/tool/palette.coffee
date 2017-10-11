
# 00000000    0000000   000      00000000  000000000  000000000  00000000
# 000   000  000   000  000      000          000        000     000
# 00000000   000000000  000      0000000      000        000     0000000
# 000        000   000  000      000          000        000     000
# 000        000   000  0000000  00000000     000        000     00000000

{ elem, drag, stopEvent, post, clamp, log, $, _ } = require 'kxk'

{ contrastColor, checkersPattern, colorDist, colorBrightness, colorGradient, grayGradient } = require '../utils'

Tool = require './tool'

WIDTH  = 255
HEIGHT = 0

class Palette extends Tool

    constructor: (@kali, cfg) ->

        cfg       ?= {}
        cfg.name  ?= 'palette'
        cfg.class ?= 'palette'
        
        cfg.halo        ?= {}
        cfg.halo.x      ?= 0
        cfg.halo.width  ?= 255+66
        
        super @kali, cfg

        HEIGHT = @kali.toolSize/2
        
        @element.style.zIndex = 1000
        @element.addEventListener 'mouseleave', @onMouseLeave
        
        @mode      = 'rgb'
        @alpha     = 1
        @value     = 2.0/3
        @luminance = 0.5

        @svg = SVG(@element).size "#{WIDTH}", "#{HEIGHT*2}"
        @svg.node.style.zIndex = 100
        @svg.node.style.position = 'absolute'
        
        @gradientGRY = grayGradient @svg
        @gradientRGB = colorGradient @svg, @luminance  
        
        @grd = @svg.group()

        @rgb = @grd.rect()
        @gry = @grd.rect()
        @col = @grd.rect()
        @alp = @grd.rect()
        
        @lum = @grd.rect()
        @lph = @grd.rect()

        @rgb.attr width:WIDTH, height:HEIGHT,   x:0, stroke: 'none',
        @gry.attr width:WIDTH, height:HEIGHT,   x:0, stroke: 'none', y:HEIGHT, fill:@gradientGRY
        @col.attr width:WIDTH, height:HEIGHT/3, x:0, stroke: 'none', y:HEIGHT, fill:@gradientCOL
        @alp.attr width:WIDTH, height:HEIGHT/3, x:0, stroke: 'none', y:HEIGHT*2-HEIGHT/3, fill:checkersPattern(@svg, @kali.toolSize/6, '#fff'), 'fill-opacity': 1-@alpha

        @lum.attr width:HEIGHT/3, height:HEIGHT/3, x:WIDTH/2-HEIGHT/3, y:HEIGHT
        
        @lph.attr width:HEIGHT/3, height:HEIGHT/3, x:WIDTH-HEIGHT/3,   y:HEIGHT*2-HEIGHT/3
        @lph.attr stroke:'black', fill:'white'

        @rgb.on 'mousedown', @selectRGB
        @gry.on 'mousedown', @selectGRY
        @col.on 'mousedown', @selectLUM
        @alp.on 'mousedown', @selectLPH

        @dot = @grd.line()
        @dot.plot [[HEIGHT*2,0], [HEIGHT*2,HEIGHT]]

        @lum.addClass 'trans'
        @lph.addClass 'trans'
        @dot.addClass 'trans'

        post.on 'palette', @onPalette

        @hide()

    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    del: ->
        
        @drag?.deactivate()
        
        @cfg.onClose?()
        
        post.removeListener 'palette', @onPalette
        
        @svg?.remove()
        @element?.remove()
        
        delete @svg
        delete @drag
        delete @element
        
    #  0000000    0000000  000000000  000   0000000   000   000  
    # 000   000  000          000     000  000   000  0000  000  
    # 000000000  000          000     000  000   000  000 0 000  
    # 000   000  000          000     000  000   000  000  0000  
    # 000   000   0000000     000     000   0000000   000   000  
    
    onPalette: (action, value) =>

        switch action
            
            when 'toggle' then @toggleVisible()
            when 'hide'   then @hide()
            
            when 'show'
                
                @setPos value
                @show()

            when 'proxy'
                
                @setProxy value
           
    # 00000000   00000000    0000000   000   000  000   000  
    # 000   000  000   000  000   000   000 000    000 000   
    # 00000000   0000000    000   000    00000      00000    
    # 000        000   000  000   000   000 000      000     
    # 000        000   000   0000000   000   000     000     
    
    setProxy: (color) ->
        
        @proxy = color.name
                
        @setClosestColor color.color, color.alpha
        
    setClosestColor: (color, alpha) ->
        
        @alpha = alpha
        @color = new SVG.Color color
        
        if @color.r == @color.g == @color.b
            @setMode 'gry'
            @value = colorBrightness @color
            @luminance = @value
        else
            @setMode 'rgb'
            @value = @valueForColor @color
            
        @updateColor @color
        @updateSliders()
        
    updateSliders: ->
        
        @gradientRGB = colorGradient @svg, @luminance
        
        @updateAlpha()
        @updateLuminance()
        
    valueForColor: (color) -> 
        
        minRGB = Math.min color.r, color.g, color.b 
        maxRGB = Math.max color.r, color.g, color.b 
        if minRGB > 0
            @luminance = 0.5+minRGB/255/2
        else
            @luminance = maxRGB/255/2
            
        @updateLuminance()
        
        minValue = 0
        minDist  = 255*3
        for i in [0..255]
            value = i/255
            c = @gradientRGB.colorAt value
            dist = colorDist c, color
            if dist < minDist
                minDist = dist
                minValue = value
        
        minValue
            
    #  0000000   000      00000000   000   000   0000000
    # 000   000  000      000   000  000   000  000   000
    # 000000000  000      00000000   000000000  000000000
    # 000   000  000      000        000   000  000   000
    # 000   000  0000000  000        000   000  000   000

    setAlpha: (f) ->

        @alpha = f

        @updateAlpha()
        @postColor 'alpha'
        @setValue @value        

    updateAlpha: ->
        
        @lph.attr x:@alpha*(WIDTH-HEIGHT/3)        
        @alp.attr 'fill-opacity': 1-@alpha
                
    # 000      000   000  00     00  000  000   000   0000000   000   000   0000000  00000000
    # 000      000   000  000   000  000  0000  000  000   000  0000  000  000       000
    # 000      000   000  000000000  000  000 0 000  000000000  000 0 000  000       0000000
    # 000      000   000  000 0 000  000  000  0000  000   000  000  0000  000       000
    # 0000000   0000000   000   000  000  000   000  000   000  000   000   0000000  00000000

    setLuminance: (f) ->

        @luminance = f

        @updateLuminance()
        @setValue @value
        
    updateLuminance: ->
        
        @gradientRGB = colorGradient @svg, @luminance
        @rgb.attr fill: @gradientRGB
        @lum.attr x: @luminance*(WIDTH-HEIGHT/3)

    # 000   000   0000000   000      000   000  00000000  
    # 000   000  000   000  000      000   000  000       
    #  000 000   000000000  000      000   000  0000000   
    #    000     000   000  000      000   000  000       
    #     0      000   000  0000000   0000000   00000000  
    
    setValue: (@value) ->
        
        @updateValue()

        post.emit 'palette', 'change', @
        @postColor()

    updateValue: ->
        
        gradient = @mode == 'rgb' and @gradientRGB or @gradientGRY
        @updateColor new SVG.Color gradient.colorAt @value        
            
    #  0000000   0000000   000       0000000   00000000
    # 000       000   000  000      000   000  000   000
    # 000       000   000  000      000   000  0000000
    # 000       000   000  000      000   000  000   000
    #  0000000   0000000   0000000   0000000   000   000

    postColor: (prop='color') ->
        
        post.emit 'color', @proxy, 
            prop:  prop
            color: @color
            alpha: @alpha
        
    updateColor: (color) ->

        @color = color

        i = contrastColor @color

        @dot.attr stroke: i
        @lum.attr stroke: i, fill: @color
        
        x = @value*WIDTH
        y = @mode == 'gry' and HEIGHT or 0
        @dot.plot [[x,y], [x,HEIGHT+y]]

        @gradientCOL = @svg.gradient 'linear', (stop) =>
            stop.at 0.0, "#000"
            stop.at 0.5, colorGradient(@svg, 0.5).colorAt @value
            stop.at 1.0, "#fff"

        @col.attr fill: @gradientCOL

    # 00     00   0000000   0000000    00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000  000   000  0000000
    # 000 0 000  000   000  000   000  000
    # 000   000   0000000   0000000    00000000

    setMode: (mode) ->

        @mode = mode

        switch @mode
            when 'gry'
                @lum.hide()
                @col.hide()
            when 'rgb'
                @lum.show()
                @col.show()
                
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   

    selectGRY: (event) => @startDrag event, @gry, @pick
    selectRGB: (event) => @startDrag event, @rgb, @pick

    selectLUM: (event) => @startDrag event, @lum, @slide
    selectLPH: (event) => @startDrag event, @lph, @slide
                
    startDrag: (event, target, cb) =>
        
        @saveTemp = @kali.tools.temp
        delete @kali.tools.temp
        
        @drag = new drag
            target: target
            handle: @element
            onMove: cb
            onStop: @stopDrag
            
        cb @drag, event
            
    stopDrag: (drag, event) =>
        
        @drag.deactivate()
        delete @drag
        @kali.tools.temp = @saveTemp
    
    #  0000000  000      000  0000000    00000000
    # 000       000      000  000   000  000
    # 0000000   000      000  000   000  0000000
    #      000  000      000  000   000  000
    # 0000000   0000000  000  0000000    00000000

    slide: (drag, event) =>

        slider = drag.target
        f = clamp 0, 1, @xPosEvent(event) / WIDTH

        if @proxy == 'fill' and event.metaKey
            
            if slider == @lum
                @luminance = f
                @updateLuminance()
            else
                @alpha = f
                @updateAlpha()

            @updateValue()
            post.emit 'palette', 'change', @
            post.emit 'stage', 'setColor', @color, @alpha
        else        
            if slider == @lum
                @setLuminance f
            else
                @setAlpha f
            
    # 00000000   000   0000000  000   000
    # 000   000  000  000       000  000
    # 00000000   000  000       0000000
    # 000        000  000       000  000
    # 000        000   0000000  000   000

    pick: (drag, event) =>

        grd = drag.target
        @setMode grd == @gry and 'gry' or 'rgb'
        
        @value = clamp 0, 1, @xPosEvent(event) / WIDTH
                
        if @proxy == 'fill' and event.metaKey
            @updateValue()
            post.emit 'palette', 'change', @
            post.emit 'stage', 'setColor', @color, @alpha
        else        
            @setValue @value

        if @mode == 'gry'
            @luminance = @value
            @updateLuminance()
            
    # 00000000  000   000  00000000  000   000  000000000   0000000
    # 000       000   000  000       0000  000     000     000
    # 0000000    000 000   0000000   000 0 000     000     0000000
    # 000          000     000       000  0000     000          000
    # 00000000      0      00000000  000   000     000     0000000

    onMouseEnter: => @addHalo()
    
    onMouseLeave: => 
        @delHalo()
        @cfg.onLeave?()
    
    xPosEvent: (event) ->
        r = $("#stage").getBoundingClientRect()
        x = event.pageX - r.left - @element.offsetLeft

    checkers: (c='#fff') ->
        @svg.pattern 10, 10, (add) ->
            add.rect(10,10).fill c
            add.rect(5,5)
            add.rect(5,5).move 5,5

module.exports = Palette

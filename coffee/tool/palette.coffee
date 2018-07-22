###
00000000    0000000   000      00000000  000000000  000000000  00000000
000   000  000   000  000      000          000        000     000
00000000   000000000  000      0000000      000        000     0000000
000        000   000  000      000          000        000     000
000        000   000  0000000  00000000     000        000     00000000
###

{ elem, drag, stopEvent, post, clamp, log, $, _ } = require 'kxk'

{   contrastColor, checkersPattern, colorDist, 
    colorGradient, grayGradient, gradientColor } = require '../utils'

Tool   = require './tool'
chroma = require 'chroma-js'

class Palette extends Tool

    constructor: (kali, cfg) ->
        
        cfg       ?= {}
        cfg.name  ?= 'palette'
        cfg.class ?= 'palette'

        width  = cfg.width  ? kali.paletteWidth
        height = cfg.height ? kali.toolSize
        
        cfg.halo        ?= {}
        cfg.halo.x      ?= 0
        cfg.halo.width  ?= width+height
        
        super kali, cfg

        @width  = width
        @height = height
        
        @element.style.zIndex = 1000
        @element.addEventListener 'mouseleave', @onMouseLeave
        
        @svg = SVG(@element).size "#{@width}", "#{@height}"
        @svg.node.style.zIndex = 100
        @svg.node.style.position = 'absolute'
                
        @grd = @svg.group()

        @rgb = @grd.rect()
        @sat = @grd.rect()
        @val = @grd.rect()
        @alx = @grd.rect()
        @alp = @grd.rect()
        
        @dot = @grd.rect()
        @ssl = @grd.rect()
        @lum = @grd.rect()
        @lph = @grd.rect()

        @rgb.attr width:@width, height:@height/2, x:0, stroke: 'none',
        @sat.attr width:@width, height:@height/6, x:0, stroke: 'none', y:@height/2
        @val.attr width:@width, height:@height/6, x:0, stroke: 'none', y:@height/2 + @height/6
        @alx.attr width:@width, height:@height/6, x:0, stroke: 'none', y:@height/2 + @height/3, fill:checkersPattern(@svg, @kali.toolSize/6, '#fff'), 'fill-opacity': 1
        @alp.attr width:@width, height:@height/6, x:0, stroke: 'none', y:@height-@height/6

        @dot.attr width:@height/6, height:@height/2-0.5, y:0.5
        @ssl.attr width:@height/6, height:@height/6,     y:@height/2
        @lum.attr width:@height/6, height:@height/6,     y:@height/2+@height/6
        @lph.attr width:@height/6, height:@height/6-0.5, y:@height-@height/6

        @rgb.on 'mousedown', @selectRGB
        @sat.on 'mousedown', @selectSAT
        @val.on 'mousedown', @selectLUM
        @alp.on 'mousedown', @selectLPH

        @dot.style fill: 'none'

        @ssl.addClass 'trans'
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
        
        if @proxy != color.name
            @proxy = color.name
            @setClosestColor color.color, color.alpha
        
    #  0000000  000       0000000    0000000  00000000   0000000  000000000  
    # 000       000      000   000  000       000       000          000     
    # 000       000      000   000  0000000   0000000   0000000      000     
    # 000       000      000   000       000  000            000     000     
    #  0000000  0000000   0000000   0000000   00000000  0000000      000     
    
    setClosestColor: (color, @alpha) ->
        
        if color.toHex?
            hsv = chroma(color.toHex()).hsv()
        else
            hsv = chroma(color).hsv()
        
        @hue        = hsv[0] if not _.isNaN hsv[0]
        @saturation = hsv[1]
        @luminance  = hsv[2]
                            
        @update()
        
    # 000   000   0000000   000      000   000  00000000  
    # 000   000  000   000  000      000   000  000       
    #  000 000   000000000  000      000   000  0000000   
    #    000     000   000  000      000   000  000       
    #     0      000   000  0000000   0000000   00000000  
    
    setHue:        (@hue)     -> @update(); @postColor 'hue'
    setAlpha:      (@alpha)    -> @update(); @postColor 'alpha'
    setLuminance:  (@luminance) -> @update(); @postColor 'luminance'
    setSaturation: (@saturation) -> @update(); @postColor 'saturation'
            
    # 00000000    0000000    0000000  000000000  
    # 000   000  000   000  000          000     
    # 00000000   000   000  0000000      000     
    # 000        000   000       000     000     
    # 000         0000000   0000000      000     

    postChange: (stage) ->
        
        post.emit 'palette', 'change', @
        
        if @proxy == 'fill' and stage
            post.emit 'stage', 'setColor', @color, @alpha
        else   
            @postColor()

    postColor: (prop='color') ->
        
        post.emit 'color', @proxy, 
            prop:       prop
            color:      @color
            alpha:      @alpha
            hue:        @hue
            luminance:  @luminance
            saturation: @saturation
            hex:        chroma(@hue, @saturation, @luminance).hex()
            
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: ->
        # log 'palette.update'
        @hue = parseInt @hue
        
        @color = new SVG.Color chroma(@hue, @saturation, @luminance, 'hsv').hex()
        i = contrastColor @color

        @dot.attr stroke: i
        @lum.attr stroke: i, fill: @color
        @ssl.attr stroke: i, fill: @color
        @lph.attr stroke: i, fill: @color
                
        @gradientRGB = colorGradient @svg, @luminance, @saturation
        
        @gradientSAT = @svg.gradient 'linear', (stop) =>
            stop.at 0.0, chroma(@hue, 0, @luminance,  'hsv').hex()
            stop.at 1.0, chroma(@hue, 1, @luminance,  'hsv').hex()

        @gradientVAL = @svg.gradient 'linear', (stop) =>
            stop.at 0.0, chroma(@hue, @saturation, 0, 'hsv').hex()
            stop.at 1.0, chroma(@hue, @saturation, 1, 'hsv').hex()

        @gradientALP = @svg.gradient 'linear', (stop) =>
            stop.at 0.0, chroma(@hue, @saturation, @luminance,  'hsv').hex(), @alpha
            stop.at 1.0, chroma(@hue, @saturation, @luminance,  'hsv').hex(), @alpha

        @rgb.attr fill: @gradientRGB
        @sat.attr fill: @gradientSAT
        @val.attr fill: @gradientVAL
        @alp.attr fill: @gradientALP
        
        r = @width-@height/6-1
        @dot.attr x: 0.5+r*@hue/360
        @lph.attr x: 0.5+r*@alpha
        @lum.attr x: 0.5+r*@luminance
        @ssl.attr x: 0.5+r*@saturation
        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   

    selectRGB: (event) => @startDrag event, @rgb, @slide
    selectSAT: (event) => @startDrag event, @ssl, @slide
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
        f = clamp 0, 1, (@xPosEvent(event)- @height/12) / (@width - @height/6)

        switch slider
            when @rgb then @setHue clamp 0, 360, f*360
            when @lum then @setLuminance   f
            when @ssl then @setSaturation  f
            when @lph then @setAlpha       f
          
        @postChange event.ctrlKey
                    
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
        s = @height/6
        @svg.pattern 10, 10, (add) ->
            add.rect(10,10).fill c
            add.rect(s,s)
            add.rect(s,s).move s,s

module.exports = Palette

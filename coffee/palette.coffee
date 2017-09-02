
# 00000000    0000000   000      00000000  000000000  000000000  00000000
# 000   000  000   000  000      000          000        000     000
# 00000000   000000000  000      0000000      000        000     0000000
# 000        000   000  000      000          000        000     000
# 000        000   000  0000000  00000000     000        000     00000000


{ elem, drag, stopEvent, post, clamp, log, $, _ } = require 'kxk'

{ colorGradient, grayGradient, checkersPattern } = require './utils'

Tool = require './tool'

WIDTH  = 255
HEIGHT = 30

class Palette extends Tool

    constructor: (@kali) ->

        super @kali, name: 'palette', class: 'palette'

        @mode      = 'rgb'
        @alpha     = 1
        @value     = 2.0/3
        @luminance = 0.5

        @svg = SVG(@element).size "#{WIDTH}", "#{HEIGHT*2}"
        
        @gradientGRY = grayGradient @svg
        @gradientRGB = colorGradient @svg, @luminance  
        
        @grd = @svg.group()

        @rgb = @grd.rect()
        @gry = @grd.rect()
        @col = @grd.rect()
        @lum = @grd.rect()
        @lph = @grd.rect()

        @rgb.attr width:WIDTH, height:HEIGHT,   x:0, stroke: 'none',
        @gry.attr width:WIDTH, height:HEIGHT,   x:0, stroke: 'none', y:HEIGHT, fill:@gradientGRY
        @col.attr width:WIDTH, height:HEIGHT/3, x:0, stroke: 'none', y:HEIGHT, fill:@gradientCOL

        @lum.attr width:HEIGHT/3, height:HEIGHT/3, x:WIDTH/2-HEIGHT/3, y:HEIGHT
        @lph.attr width:HEIGHT/3, height:HEIGHT/3, x:WIDTH-HEIGHT/3,   y:HEIGHT*2-HEIGHT/3
        @lph.attr stroke:'black', fill:'white'

        @col.on 'mousedown', @selectLUM
        @lph.on 'mousedown', @selectLPH
        @rgb.on 'mousedown', @selectRGB
        @gry.on 'mousedown', @selectGRY

        @dot = @grd.line()
        @dot.plot [[HEIGHT*2,0], [HEIGHT*2,HEIGHT]]

        @lum.addClass 'trans'
        @dot.addClass 'trans'

        post.on 'palette', @onPalette

        @hide()

    #  0000000    0000000  000000000  000   0000000   000   000  
    # 000   000  000          000     000  000   000  0000  000  
    # 000000000  000          000     000  000   000  000 0 000  
    # 000   000  000          000     000  000   000  000  0000  
    # 000   000   0000000     000     000   0000000   000   000  
    
    onPalette: (action, value) =>

        log 'onPalette', action
        switch action
            
            when 'hide' then @hide()
            
            when 'show'
                
                @setPos value
                @show()

            when 'proxy'
                
                @proxy     = value.name
                @mode      = value.mode
                @alpha     = value.alpha
                @value     = value.value
                @luminance = value.luminance
                @color     = value.color
                
                @gradientRGB = colorGradient @svg, @luminance
                @rgb.attr fill: @gradientRGB
                @lph.attr x:@alpha*(WIDTH-HEIGHT/3)
                @lum.attr x:@luminance*(WIDTH-HEIGHT/3)
                
                @setColor @value
                
    selectGRY: (event) => @pick  event, @gry, @selectGRY
    selectRGB: (event) => @pick  event, @rgb, @selectRGB

    selectLUM: (event) => @slide event, @lum, @selectLUM
    selectLPH: (event) => @slide event, @lph, @selectLPH

    #  0000000   000      00000000   000   000   0000000
    # 000   000  000      000   000  000   000  000   000
    # 000000000  000      00000000   000000000  000000000
    # 000   000  000      000        000   000  000   000
    # 000   000  0000000  000        000   000  000   000

    setAlpha: (f) ->

        @alpha = f

        @lph.attr x:@alpha*(WIDTH-HEIGHT/3)

        post.emit 'color', @proxy, 'alpha', @alpha
        
        @setColor @value        

    # 000      000   000  00     00  000  000   000   0000000   000   000   0000000  00000000
    # 000      000   000  000   000  000  0000  000  000   000  0000  000  000       000
    # 000      000   000  000000000  000  000 0 000  000000000  000 0 000  000       0000000
    # 000      000   000  000 0 000  000  000  0000  000   000  000  0000  000       000
    # 0000000   0000000   000   000  000  000   000  000   000  000   000   0000000  00000000

    setLuminance: (f) ->

        @luminance = f

        @gradientRGB = colorGradient @svg, @luminance

        @rgb.attr fill: @gradientRGB
        @lum.attr x: @luminance*(WIDTH-HEIGHT/3)
            
        @setColor @value

    #  0000000   0000000   000       0000000   00000000
    # 000       000   000  000      000   000  000   000
    # 000       000   000  000      000   000  0000000
    # 000       000   000  000      000   000  000   000
    #  0000000   0000000   0000000   0000000   000   000

    setColor: (f) ->

        @value = f
        
        gradient = @mode == 'rgb' and @gradientRGB or @gradientGRY

        @updateColor new SVG.Color gradient.colorAt @value

        x = @value*WIDTH
        y = @mode == 'gry' and HEIGHT or 0
        @dot.plot [[x,y], [x,HEIGHT+y]]

        @gradientCOL = @svg.gradient 'linear', (stop) =>
            stop.at 0.0, "#000"
            stop.at 0.5, colorGradient(@svg, 0.5).colorAt @value
            stop.at 1.0, "#fff"

        @col.attr fill: @gradientCOL
         
        post.emit 'palette', 'change', @
        post.emit 'color', @proxy, 'color', @color

    updateColor: (color) ->

        @color = color

        i = @invert @color

        @dot.attr stroke: i
        @lum.attr stroke: i, fill:   @color

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

    #  0000000  000      000  0000000    00000000
    # 000       000      000  000   000  000
    # 0000000   000      000  000   000  0000000
    #      000  000      000  000   000  000
    # 0000000   0000000  000  0000000    00000000

    slide: (event, slider, cb) =>

        f = clamp 0, 1, @xPosEvent(event) / WIDTH

        if slider == @lum
            @setLuminance f
        else
            @setAlpha f

        @moveEvents cb
        stopEvent event

    # 00000000   000   0000000  000   000
    # 000   000  000  000       000  000
    # 00000000   000  000       0000000
    # 000        000  000       000  000
    # 000        000   0000000  000   000

    pick: (event, grd, cb) =>

        @setMode grd == @gry and 'gry' or 'rgb'
        @setColor clamp 0, 1, @xPosEvent(event) / WIDTH
        @moveEvents cb
        stopEvent event

    # 00000000  000   000  00000000  000   000  000000000   0000000
    # 000       000   000  000       0000  000     000     000
    # 0000000    000 000   0000000   000 0 000     000     0000000
    # 000          000     000       000  0000     000          000
    # 00000000      0      00000000  000   000     000     0000000

    moveEvents: (cb) ->

        @clearEvents @moveCB
        @moveCB = cb
        window.addEventListener 'mousemove', cb
        window.addEventListener 'mouseup', => @clearEvents @moveCB

    clearEvents: (cb) ->

        window.removeEventListener 'mousemove', cb
        window.removeEventListener 'mouseup',   cb

    xPosEvent: (event) ->
        r = $("#stage").getBoundingClientRect()
        x = event.pageX - r.left - @element.offsetLeft

    invert: (c) ->
        if c.r == c.g == c.b
            return new SVG.Color c.r+c.g+c.b < 255+128 and '#fff' or '#000'
        if @luminance < 0.5
            new SVG.Color '#fff'
        else
            new SVG.Color '#000'

    checkers: (c='#fff') ->
        @svg.pattern 10, 10, (add) ->
            add.rect(10,10).fill c
            add.rect(5,5)
            add.rect(5,5).move 5,5

module.exports = Palette

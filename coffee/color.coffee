
#  0000000   0000000   000       0000000   00000000   
# 000       000   000  000      000   000  000   000  
# 000       000   000  000      000   000  0000000    
# 000       000   000  000      000   000  000   000  
#  0000000   0000000   0000000   0000000   000   000  

{ elem, drag, stopEvent, post, clamp, log, $
} = require 'kxk'
Tool = require './tool'

WIDTH  = 255
HEIGHT = 30

class Color extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @svg = SVG(@element).size "#{WIDTH+HEIGHT*2}", "#{HEIGHT*2}" 
        
        @g = @svg.group()
                    
        @gradientGRY = @svg.gradient 'linear', (stop) ->
            stop.at 0.0, "#000"
            stop.at 1.0, "#fff"
        
        @sqr = @g.rect()
        @bot = @g.rect()
        @top = @g.rect()
        
        @sqr.attr width:HEIGHT*2, height:HEIGHT*2, stroke: 'none', fill: @checkers()
        @bot.attr width:HEIGHT*2, height:HEIGHT,   stroke: 'none', y:HEIGHT
        @top.attr width:HEIGHT*2, height:HEIGHT,   stroke: 'none'
            
        @grd = @g.group()
        
        @rgb = @grd.rect()
        @gry = @grd.rect()
        @col = @grd.rect()
        @lum = @grd.rect()
        @lph = @grd.rect()
        
        @rgb.attr width:WIDTH, height:HEIGHT,   x:HEIGHT*2, stroke: 'none', 
        @gry.attr width:WIDTH, height:HEIGHT,   x:HEIGHT*2, stroke: 'none', y:HEIGHT, fill:@gradientGRY
        @col.attr width:WIDTH, height:HEIGHT/3, x:HEIGHT*2, stroke: 'none', y:HEIGHT, fill:@gradientCOL
            
        @lum.attr width:HEIGHT/3, height:HEIGHT/3, x:HEIGHT*2+WIDTH/2-HEIGHT/3, y:HEIGHT
        @lph.attr width:HEIGHT/3, height:HEIGHT/3, x:HEIGHT*2+WIDTH-HEIGHT/3,   y:HEIGHT*2-HEIGHT/3
        @lph.attr stroke:'black', fill:'white'
            
        @col.on 'mousedown', @selectLUM
        @lph.on 'mousedown', @selectLPH            
        @rgb.on 'mousedown', @selectRGB
        @gry.on 'mousedown', @selectGRY
        
        @dot = @grd.line()
        @dot.plot [[HEIGHT*2,0], [HEIGHT*2,HEIGHT]]
        
        @bot.addClass 'trans'
        @top.addClass 'trans'
        @lum.addClass 'trans'
        @dot.addClass 'trans'
        @sqr.addClass 'trans'
                
        @mode  = 'rgb'
        @alpha = 1
        @value = 2.0/3
        @setLuminance 0.5
                
    selectGRY: (event) => @pick  event, @gry, @selectGRY
    selectRGB: (event) => @pick  event, @rgb, @selectRGB
        
    selectLUM: (event) => @slide event, @lum, @selectLUM
    selectLPH: (event) => @slide event, @lph, @selectLPH

    onClick: => @toggleGradient()
    
    #  0000000   000      00000000   000   000   0000000   
    # 000   000  000      000   000  000   000  000   000  
    # 000000000  000      00000000   000000000  000000000  
    # 000   000  000      000        000   000  000   000  
    # 000   000  0000000  000        000   000  000   000  
    
    setAlpha: (f) -> 
        
        @alpha = f
        
        @setColor @value
        
        @lph.attr x:HEIGHT*2+f*(WIDTH-HEIGHT/3)    
    
    # 000      000   000  00     00  000  000   000   0000000   000   000   0000000  00000000  
    # 000      000   000  000   000  000  0000  000  000   000  0000  000  000       000       
    # 000      000   000  000000000  000  000 0 000  000000000  000 0 000  000       0000000   
    # 000      000   000  000 0 000  000  000  0000  000   000  000  0000  000       000       
    # 0000000   0000000   000   000  000  000   000  000   000  000   000   0000000  00000000  
    
    setLuminance: (f) ->
        
        @luminance = f
        
        @gradientRGB = @colorGradient f   
        
        @rgb.attr
            fill: @gradientRGB
         
        if @mode == 'rgb'
            @setColor @value
            
        @lum.attr x:HEIGHT*2+f*(WIDTH-HEIGHT/3)    

    #  0000000   0000000   000       0000000   00000000   
    # 000       000   000  000      000   000  000   000  
    # 000       000   000  000      000   000  0000000    
    # 000       000   000  000      000   000  000   000  
    #  0000000   0000000   0000000   0000000   000   000  
        
    setColor: (f) ->
        
        gradient = @mode == 'rgb' and @gradientRGB or @gradientGRY
        
        @value = f
        @color = new SVG.Color gradient.colorAt @value
        
        i = @invert @color
        
        @top.style
            fill: @color
            
        @bot.style
            fill: @color
            'fill-opacity': @alpha
            
        @dot.attr
            stroke: i

        x = HEIGHT*2 + @value*WIDTH
        y = @mode == 'gry' and HEIGHT or 0 
        @dot.plot [[x,y], [x,HEIGHT+y]]
            
        @gradientCOL = @svg.gradient 'linear', (stop) =>
            stop.at 0.0, "#000"
            stop.at 0.5, @colorGradient(0.5).colorAt @value
            stop.at 1.0, "#fff"        
#             
        @col.attr
            fill: @gradientCOL
            
        @lum.attr 
            stroke: i
            fill:   @color

    #  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  
    # 000        000   000  000   000  000   000  000  000       0000  000     000     
    # 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     
    # 000   000  000   000  000   000  000   000  000  000       000  0000     000     
    #  0000000   000   000  000   000  0000000    000  00000000  000   000     000     
    
    colorGradient: (f) ->
        
        c = parseInt 255 * clamp 0, 1, f*2
        h = parseInt 255 * clamp 0, 1, (f-0.5)*2
        
        @svg.gradient 'linear', (stop) ->
            stop.at 0.0,   new SVG.Color r:c, g:h, b:h
            stop.at 1.0/6, new SVG.Color r:c, g:c, b:h
            stop.at 2.0/6, new SVG.Color r:h, g:c, b:h
            stop.at 3.0/6, new SVG.Color r:h, g:c, b:c
            stop.at 4.0/6, new SVG.Color r:h, g:h, b:c
            stop.at 5.0/6, new SVG.Color r:c, g:h, b:c
            stop.at 6.0/6, new SVG.Color r:c, g:h, b:h
            
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
        
        f = clamp 0, 1, (@xPosEvent(event)-HEIGHT*2) / WIDTH
        
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
        @setColor clamp 0, 1, (@xPosEvent(event)-HEIGHT*2) / WIDTH
                    
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
            
    # 000000000   0000000    0000000    0000000   000      00000000  
    #    000     000   000  000        000        000      000       
    #    000     000   000  000  0000  000  0000  000      0000000   
    #    000     000   000  000   000  000   000  000      000       
    #    000      0000000    0000000    0000000   0000000  00000000  
    
    toggleGradient: =>

        if @grd.visible()
            @grd.hide()
            @svg.width HEIGHT*2
        else
            @grd.show()
            @svg.width WIDTH+HEIGHT*2
            
module.exports = Color


# 00000000   000   0000000  000   000  00000000  00000000 
# 000   000  000  000       000  000   000       000   000
# 00000000   000  000       0000000    0000000   0000000  
# 000        000  000       000  000   000       000   000
# 000        000   0000000  000   000  00000000  000   000

{ elem, drag, stopEvent, post, clamp, log, $
} = require 'kxk'

WIDTH  = 255
HEIGHT = 25

class Picker

    constructor: (parent) ->
        
        @element = elem 'div', class: 'picker'
        parent.appendChild @element
        
        post.on 'picker', (msg) =>
            switch msg
                when 'toggle' then @toggleDisplay()
        
        @svg = SVG(@element).size "#{WIDTH+HEIGHT*2}", "#{HEIGHT*2}" 
        @svg.addClass 'pickerSVG'
        
        @g = @svg.group()
                    
        @gradientGRY = @svg.gradient 'linear', (stop) ->
            stop.at 0.0, "#000"
            stop.at 1.0, "#fff"
        
        @sqr = @g.rect()
        @sqr.attr
            width:  HEIGHT*2
            height: HEIGHT*2

        @bot = @g.rect()
        @bot.addClass 'trans'
        @bot.attr
            width:  HEIGHT*2
            height: HEIGHT
            y:      HEIGHT
            stroke: 'none'

        @top = @g.rect()
        @top.addClass 'trans'
        @top.attr
            width:  HEIGHT*2
            height: HEIGHT
            stroke: 'none'
            
        @grd = @g.group()
        
        @rgb = @grd.rect()
        @rgb.attr
            width:  WIDTH
            height: HEIGHT
            x:      HEIGHT*2
            
        @gry = @grd.rect()
        @gry.attr
            width:  WIDTH
            height: HEIGHT
            x:      HEIGHT*2
            y:      HEIGHT
            fill:   @gradientGRY

        @col = @grd.rect()
        @col.attr
            width:  WIDTH
            height: HEIGHT/3
            x:      HEIGHT*2
            y:      HEIGHT
            fill:   @gradientCOL
            
        @lum = @grd.rect()
        @lum.addClass 'luminanceSlider'
        @lum.attr 
            width:  HEIGHT/3
            height: HEIGHT/3
            y:      HEIGHT
            x:      HEIGHT*2+WIDTH/2-HEIGHT/6
            stroke: 'white'
            fill:   'black'
            
        @lph = @grd.rect()
        @lph.attr 
            width:  HEIGHT/3
            height: HEIGHT/3
            y:      HEIGHT*2-HEIGHT/3
            x:      HEIGHT*2+WIDTH-HEIGHT/6
            stroke: 'black'
            fill:   'white'
            
        @col.on 'mousedown', @selectLUM
        @lph.on 'mousedown', @selectLPH            
        @rgb.on 'mousedown', @selectRGB
        @gry.on 'mousedown', @selectGRY

        @dot = @grd.line()
        @dot.addClass 'colorSlider'
        @dot.plot [[HEIGHT*2,0], [HEIGHT*2,HEIGHT]]
        
        @drag = new drag 
            handle: @element
            target: @element
            onStart: => @sqr.on 'mouseup', @toggleGradient
            onMove:  (e) => 
                @sqr.off 'mouseup', @toggleGradient
                @element.style.left = "#{@element.offsetLeft+e.delta.x}px"
                @element.style.top  = "#{@element.offsetTop+e.delta.y}px"

        @mode       = 'rgb'
        @alpha      = 1
        @value      = 2.0/3
        @setLuminance 0.5
                
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
        @setColor @value
    
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
        
        @sqr.attr
            fill:   @checkers @color
            stroke: i

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

        # @lph.attr
            # x: HEIGHT*2 + @alpha * WIDTH - HEIGHT/6
            
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
        
        x = clamp HEIGHT*2, WIDTH+HEIGHT*2, @xPosEvent event
        slider.attr x: x-HEIGHT/6
    
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
        @clearEvents cb
        window.addEventListener 'mousemove', cb
        window.addEventListener 'mouseup', => @clearEvents cb
        
    clearEvents: (cb) ->
        window.removeEventListener 'mousemove', cb
        window.removeEventListener 'mousemove', cb

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

    checkers: (c) ->
        @svg.pattern 10, 10, (add) ->
            add.rect(10,10).fill "#fff"
            add.rect(5,5)
            add.rect(5,5).move 5,5 
            
    # 000000000   0000000    0000000    0000000   000      00000000  
    #    000     000   000  000        000        000      000       
    #    000     000   000  000  0000  000  0000  000      0000000   
    #    000     000   000  000   000  000   000  000      000       
    #    000      0000000    0000000    0000000   0000000  00000000  
    
    toggleDisplay: =>
        if @element.style.display == 'none'
            @element.style.display = 'initial'
        else
            @element.style.display = 'none'
        
    toggleGradient: =>
        if @grd.visible()
            @grd.hide()
            @svg.width HEIGHT*2
        else
            @grd.show()
            @svg.width WIDTH+HEIGHT*2
        @sqr.off 'mouseup', @toggleGradient
    
module.exports = Picker

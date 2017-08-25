
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
        
        @gradientRGB = @svg.gradient 'linear', (stop) ->
            stop.at 0.0,   "#f00"
            stop.at 1.0/6, "#ff0"
            stop.at 2.0/6, "#0f0"
            stop.at 3.0/6, "#0ff"
            stop.at 4.0/6, "#00f"
            stop.at 5.0/6, "#f0f"
            stop.at 6.0/6, "#f00"
            
        @gradientGRY = @svg.gradient 'linear', (stop) ->
            stop.at 0.0, "#000"
            stop.at 1.0, "#fff"
        
        @sqr = @g.rect()
        @sqr.attr
            width:  HEIGHT*2
            height: HEIGHT*2
            stroke: 'gray'

        @grd = @g.group()
        
        @rgb = @grd.rect()
        @rgb.attr
            width:  WIDTH
            height: HEIGHT
            x:      HEIGHT*2
            fill:   @gradientRGB
            
        @gry = @grd.rect()
        @gry.attr
            width:  WIDTH
            height: HEIGHT
            x:      HEIGHT*2
            y:      HEIGHT
            fill:   @gradientGRY

        @lum = @grd.rect()
        @lum.attr 
            width:  HEIGHT/4
            height: HEIGHT/4
            y:      HEIGHT
            x:      HEIGHT*2+WIDTH/2-HEIGHT/8
            stroke: 'white'
            fill:   'black'
            
        @lph = @grd.rect()
        @lph.attr 
            width:  HEIGHT/4
            height: HEIGHT/4
            y:      HEIGHT*2-HEIGHT/4
            x:      HEIGHT*2+WIDTH-HEIGHT/8
            stroke: 'black'
            fill:   'white'
            
        @lum.on 'mousedown', @selectLUM
        @lph.on 'mousedown', @selectLPH            
        @rgb.on 'mousedown', @selectRGB
        @gry.on 'mousedown', @selectGRY

        @dot = @grd.line()
        @dot.addClass 'dot'
        @dot.plot [[HEIGHT*2,0], [HEIGHT*2,HEIGHT]]
        
        @drag = new drag 
            handle: @element
            target: @element
            onStart: => @sqr.on 'mouseup', @toggleGradient
            onMove:  (e) => 
                @sqr.off 'mouseup', @toggleGradient
                @element.style.left = "#{@element.offsetLeft+e.delta.x}px"
                @element.style.top  = "#{@element.offsetTop+e.delta.y}px"

    selectRGB: (event) => @pick event, @gradientRGB, @rgb, @selectRGB 
    selectGRY: (event) => @pick event, @gradientGRY, @gry, @selectGRY
    
    selectLUM: (event) => @slide event, @lum, @selectLUM
    selectLPH: (event) => @slide event, @lph, @selectLPH
        
    #  0000000  000      000  0000000    00000000  
    # 000       000      000  000   000  000       
    # 0000000   000      000  000   000  0000000   
    #      000  000      000  000   000  000       
    # 0000000   0000000  000  0000000    00000000  
    
    slide: (event, slider, cb) =>
        
        x = clamp HEIGHT*2, WIDTH+HEIGHT*2, @xPosEvent event
        
        slider.attr x: x-HEIGHT/8

        @moveEvents cb
        stopEvent event
    
    # 00000000   000   0000000  000   000  
    # 000   000  000  000       000  000   
    # 00000000   000  000       0000000    
    # 000        000  000       000  000   
    # 000        000   0000000  000   000  
    
    pick: (event, gradient, grd, cb) =>

        f = clamp 0, 1, (@xPosEvent(event) - HEIGHT*2) / WIDTH
        c = gradient.colorAt f
        i = @invert c
        @sqr.attr
            fill:   c
            stroke: i
        @dot.attr
            stroke: i
            
        x = HEIGHT*2 + f*WIDTH
        if grd == @gry
            y = HEIGHT
            @lum.hide()
        else
            y = 0
            @lum.show()
        @dot.plot [[x,y], [x,HEIGHT+y]]
        
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
        
    invert: (c) -> new SVG.Color r:255-c.r, g:255-c.g, b:255-c.b
       
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


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
            y:      HEIGHT
            x:      HEIGHT*2
            fill:   @gradientGRY
            
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
    
    pick: (event, gradient, grd, select) =>

        r = $("#stage").getBoundingClientRect()
        x = event.pageX - r.left - @element.offsetLeft
        
        f = clamp 0, 1, (x - HEIGHT*2) / WIDTH
        
        i = @invert gradient.colorAt f
        @sqr.attr 
            fill:   gradient.colorAt f
            stroke: i
        @dot.attr
            fill:   gradient.colorAt f
            stroke: i
            
        x = f * WIDTH+HEIGHT*2
        y = grd == @gry and HEIGHT or 0
        @dot.plot [[x,y], [x,HEIGHT+y]]
        
        @clearPickEvents select
        window.addEventListener 'mousemove', select
        window.addEventListener 'mouseup', => @clearPickEvents select
        
        stopEvent event

    clearPickEvents: (select) =>
        window.removeEventListener 'mousemove', select
        window.removeEventListener 'mousemove', select
        
    invert: (c) ->
        i = c
        i.r = 255 - c.r
        i.g = 255 - c.g
        i.b = 255 - c.b
        i
       
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

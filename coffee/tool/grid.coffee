
#  0000000   00000000   000  0000000
# 000        000   000  000  000   000
# 000  0000  0000000    000  000   000
# 000   000  000   000  000  000   000
#  0000000   000   000  000  0000000

{ stopEvent, elem, prefs, post, log, _ } = require 'kxk'

{ colorBrightness } = require '../utils'

Tool = require './tool'

class Grid extends Tool

    constructor: (@kali, cfg) ->

        super @kali, cfg

        @div = elem 'div', id: 'grid'
        @kali.element.insertBefore @div, @kali.stage.element
        @svg = SVG(@div).size '100%', '100%'
        @svg.addClass 'gridSVG'
        @svg.clear()
        @svg.hide()
        
        visible  = prefs.get 'grid:visible',  false
        contrast = prefs.get 'grid:contrast', false
        
        @initTitle()
        @initButtons [
            text:   '100'
            name:   'grid'
            toggle: visible
            action: @toggleGrid
        ]
        @initButtons [
            text: 'contrast'
            name: 'contrast'
            toggle: contrast
            action: @onContrast
        ]

        post.on 'stage', @onStage

        @grid = @svg.group()
        
        @setVisible visible

    #  0000000   0000000   000   000  000000000  00000000    0000000    0000000  000000000  
    # 000       000   000  0000  000     000     000   000  000   000  000          000     
    # 000       000   000  000 0 000     000     0000000    000000000  0000000      000     
    # 000       000   000  000  0000     000     000   000  000   000       000     000     
    #  0000000   0000000   000   000     000     000   000  000   000  0000000      000     
    
    onContrast: => 
        
        prefs.set 'grid:contrast', @button('contrast').toggle
        @drawGrid()
        
    # 0000000    00000000    0000000   000   000  
    # 000   000  000   000  000   000  000 0 000  
    # 000   000  0000000    000000000  000000000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000  00     00  
    
    drawGrid: ->

        @svg.show()
        @grid.clear()

        z = @stage.zoom
        v = @stage.svg.viewbox()
        vx = v.x
        vy = v.y
        vw = v.width
        vh = v.height
        sx = @svg.x()
        sy = @svg.y()
        sw = @svg.width()
        sh = @svg.height()
        
        contrast = @button('contrast').toggle
        bright = colorBrightness @stage.color 
        if bright > 0.5
            colorStrong = '#000'
        else
            colorStrong = '#fff'
            
        if 0.5 <= bright <= 0.75
            colorWeak = '#555'
        else if 0.25 <= bright <= 0.5
            colorWeak = '#aaa'
        else
            colorWeak = '#888'
            
        log 'colors', colorStrong, colorWeak
        
        draw = (s, a) =>

            ox = vx % s
            oy = vy % s
            xn = Math.ceil vw / s
            yn = Math.ceil vh / s

            style =
                stroke: colorWeak
                'stroke-width': 1
                'stroke-opacity': contrast and 1 or 0.05 + a * 0.5

            for x in [0..xn]
                v = (x*s-ox)*z
                @grid.line(v,sy,v,sh).style style

            for y in [0..yn]
                v = (y*s-oy)*z
                @grid.line(sx,v,sw,v).style style

        spacing = @button 'grid' 
                
        if z >= 100

            spacing.innerHTML = '1'
            draw 1, z/1000
            draw 10, 1.0

        else if z >= 10

            spacing.innerHTML = '10'
            draw 10, z/100
            draw 100, 1.0

        else if z >= 1

            spacing.innerHTML = '100'
            draw 100, z/10
            draw 1000, 1.0

        else
            spacing.innerHTML = '1000'
            draw 1000, z

        style = 
            stroke: colorStrong
            fill:   @stage.color
            'stroke-width':     1
            'stroke-opacity':   contrast and 1 or 0.15
            
        if vx < 0 and vx+vw > 0
            v = -vx*z
            @grid.line(v,sy,v,sh).style style

        if vy < 0 and vy+vh > 0
            v = -vy*z
            @grid.line(sx,v,sw,v).style style
            
        if vx < 0 and vx+vw > 0 and vy < 0 and vy+vh > 0
            style['stroke-opacity'] = contrast and 1 or 0.4
            @grid.circle(10).style(style).cx(-vx*z).cy(-vy*z)
            
    onStage: (action) => 
        if action in ['viewbox', 'color'] and @gridVisible() then @drawGrid()

    setVisible: (v) -> if v then @showGrid() else @hideGrid()
    toggleGrid:  => @setVisible not @gridVisible()
    gridVisible: -> @svg.visible()
    showGrid:    -> @drawGrid(); prefs.set 'grid:visible', true
    hideGrid:    -> @svg.hide(); prefs.set 'grid:visible', false; @button('grid').innerHTML = 'Show'

module.exports = Grid

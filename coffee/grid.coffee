
#  0000000   00000000   000  0000000    
# 000        000   000  000  000   000  
# 000  0000  0000000    000  000   000  
# 000   000  000   000  000  000   000  
#  0000000   000   000  000  0000000    

{ stopEvent, elem, post, log, _ } = require 'kxk'

Tool = require './tool'

class Grid extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg

        @div = elem 'div', id: 'grid'
        @kali.element.insertBefore @div, @kali.stage.element
        @svg = SVG(@div).size '100%', '100%' 
        @svg.addClass 'gridSVG'
        @svg.clear()

        @title = @element.appendChild elem 'div', class: 'title', text: '1000'
        
        post.on 'stage', @onStage
        
        @grid = @svg.group()
        
    drawGrid: ->
        
        @svg.show()
        @grid.clear()
        
        z = @kali.stage.zoom
        v = @kali.stage.svg.viewbox()
        vx = v.x
        vy = v.y
        vw = v.width
        vh = v.height
        sx = @svg.x()
        sy = @svg.y()
        sw = @svg.width()
        sh = @svg.height()
        
        draw = (svg, grid, s, a) ->
            
            ox = vx % s
            oy = vy % s
            xn = Math.ceil vw / s
            yn = Math.ceil vh / s
            
            style = stroke: '#888', 'stroke-width': 1, 'stroke-opacity': 0.05 + a * 0.5
            
            for x in [0..xn]
                v = (x*s-ox)*z
                grid.line(v,sy,v,sh).style(style)#.addClass "grid-#{s}"
            for y in [0..yn]
                v = (y*s-oy)*z
                grid.line(sx,v,sw,v).style(style)#.addClass "grid-#{s}"
        
        if z >= 100  
            
            @title.innerHTML = '1'
            draw @svg, @grid, 1, z/1000
            draw @svg, @grid, 10, 1.0
            
        else if z >= 10
            
            @title.innerHTML = '10'
            draw @svg, @grid, 10, z/100
            draw @svg, @grid, 100, 1.0
            
        else if z >= 1
            
            @title.innerHTML = '100'
            draw @svg, @grid, 100, z/10
            draw @svg, @grid, 1000, 1.0
            
        else
            @title.innerHTML = '1000'
            draw @svg, @grid, 1000, z
                
    onStage: (prop, value) => if prop == 'viewbox' and @gridVisible() then @drawGrid()
            
    toggleGrid:  -> if @gridVisible() then @hideGrid() else @showGrid()
    gridVisible: -> @svg.visible()
    showGrid:    -> @drawGrid()
    hideGrid:    -> @svg.hide()
    
module.exports = Grid

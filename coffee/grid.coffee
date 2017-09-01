
#  0000000   00000000   000  0000000    
# 000        000   000  000  000   000  
# 000  0000  0000000    000  000   000  
# 000   000  000   000  000  000   000  
#  0000000   000   000  000  0000000    

{ stopEvent, elem, post, log, _ } = require 'kxk'

Tool = require './tool'

class Grid extends Tool

    constructor: (@kali, cfg) ->
        
        cfg.name = 'grid'
        cfg.text = 'grid'
        super @kali, cfg

        @div = elem 'div', id: 'grid'
        @kali.element.insertBefore @div, @kali.stage.element
        @svg = SVG(@div).size '100%', '100%' 
        @svg.addClass 'gridSVG'
        @svg.clear()
                
        post.on 'stage', @onStage
        
        @grid = @svg.group()
        
    drawGrid: ->
        
        @svg.show()
        @grid.clear()
        
        z = @kali.stage.zoom
        v = @kali.stage.svg.viewbox()
        
        draw = (s, a) =>
            
            ox = v.x % s
            oy = v.y % s
            xn = Math.ceil v.width  / s
            yn = Math.ceil v.height / s
            
            style = stroke: '#888', 'stroke-width': 0.25, 'stroke-opacity': a
            
            for x in [0..xn]
                v = (x*s-ox)*z
                @grid.line(v,@svg.y(),v,@svg.height()).style style
            for y in [0..yn]
                v = (y*s-oy)*z
                @grid.line(@svg.x(),v,@svg.width(),v).style style
        
        if z > 100  
            draw 1, z/1000
            draw 10, 1-z/100
        else if z > 10
            draw 10, z/100
            draw 100, 1-z/10
        else if z > 1
            draw 100, 1-z/10
            draw 1000, z
        else
            draw 1000, z
                
    onStage: (prop, value) => if prop == 'viewbox' and @gridVisible() then @drawGrid()
            
    toggleGrid:  -> if @gridVisible() then @hideGrid() else @showGrid()
    gridVisible: -> @svg.visible()
    showGrid:    -> @drawGrid()
    hideGrid:    -> @svg.hide()
    
module.exports = Grid

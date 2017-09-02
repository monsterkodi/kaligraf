
#  0000000   0000000   000       0000000   00000000   
# 000       000   000  000      000   000  000   000  
# 000       000   000  000      000   000  0000000    
# 000       000   000  000      000   000  000   000  
#  0000000   0000000   0000000   0000000   000   000  

{ elem, drag, stopEvent, post, clamp, first, log, $, _ } = require 'kxk'

{ colorGradient, grayGradient, checkersPattern } = require './utils'

Tool = require './tool'

class Color extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @svg = SVG(@element).size '100%', '100%' 
        
        @g = @svg.group()
                    
        @gradientGRY = grayGradient @svg

        @sqr = @g.rect()
        @bot = @g.rect()
        @top = @g.rect()
        
        @sqr.attr width:'100%', height:'100%', stroke: 'none', fill: checkersPattern(@svg)
        @bot.attr width:'100%', height:'50%',  stroke: 'none', y:'50%'
        @top.attr width:'100%', height:'50%',  stroke: 'none'
            
        @sqr.addClass 'trans'
        
        @mode  = 'rgb'
        @alpha = 1
        @value = 2.0/3
        @setLuminance 0.5

    initChildren: ->
        
        super
        
        if @name == 'stroke'

            fill = first @children
            @element.appendChild fill.element
            fill.element.style.left   = "10px" 
            fill.element.style.top    = "10px"            
            fill.element.style.width  = "40px"            
            fill.element.style.height = "40px"            
            @showChildren()
    
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (e) => log @name
    onMouseEnter: => log 'enter', @name; super
    onMouseLeave: => log 'leave', @name
    
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
        
        @gradientRGB = colorGradient @svg, f   
        
        if @mode == 'rgb'
            @setColor @value
            post.emit 'color', @name, 'color', @color
            
        post.emit 'color', @name, 'luminance', @luminance

    #  0000000   0000000   000       0000000   00000000   
    # 000       000   000  000      000   000  000   000  
    # 000       000   000  000      000   000  0000000    
    # 000       000   000  000      000   000  000   000  
    #  0000000   0000000   0000000   0000000   000   000  

    setColor: (f) ->
        
        gradient = @mode == 'rgb' and @gradientRGB or @gradientGRY
        
        @value = f
        
        @updateColor new SVG.Color gradient.colorAt @value
        
    updateColor: (color) ->
        
        @top.style
            fill: @color
            
        @bot.style
            fill: @color
            'fill-opacity': @alpha
            
module.exports = Color

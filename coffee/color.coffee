
#  0000000   0000000   000       0000000   00000000   
# 000       000   000  000      000   000  000   000  
# 000       000   000  000      000   000  0000000    
# 000       000   000  000      000   000  000   000  
#  0000000   0000000   0000000   0000000   000   000  

{ elem, drag, stopEvent, post, clamp, first, pos, log, $, _ } = require 'kxk'

{ colorGradient, grayGradient, checkersPattern } = require './utils'

Tool    = require './tool'
Palette = require './palette'

class Color extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @svg = SVG(@element).size '100%', '100%' 
        
        @g = @svg.group()
                            
        @sqr = @g.rect()
        @bot = @g.rect()
        @top = @g.rect()
        
        @sqr.attr width:'100%', height:'100%', stroke: 'none', fill: checkersPattern(@svg)
        @bot.attr width:'100%', height:'50%',  stroke: 'none', y:'50%'
        @top.attr width:'100%', height:'50%',  stroke: 'none'
            
        @bot.addClass 'trans'
        @top.addClass 'trans'
        @sqr.addClass 'trans'
        
        @mode      = 'rgb'
        @alpha     = 1
        @value     = 2/3
        @luminance = 0.5
        @color     = new SVG.Color "#00f"
        
        post.on 'palette', @onPalette

    # 00000000    0000000   000      00000000  000000000  000000000  00000000  
    # 000   000  000   000  000      000          000        000     000       
    # 00000000   000000000  000      0000000      000        000     0000000   
    # 000        000   000  000      000          000        000     000       
    # 000        000   000  0000000  00000000     000        000     00000000  
    
    onPalette: (action, value) =>
                
        if action == 'change' and value.proxy == @name
                
            @set value

    set: (v) ->
        
        @luminance = v.luminance if v.luminance?
        @color     = v.color     if v.color?
        @alpha     = v.alpha     if v.alpha?
        @value     = v.value     if v.value?
        @mode      = v.mode      if v.mode?
        
        @update()
        
    # 00000000  000  000      000             0000000  000000000  00000000    0000000   000   000  00000000    
    # 000       000  000      000            000          000     000   000  000   000  000  000   000         
    # 000000    000  000      000            0000000      000     0000000    000   000  0000000    0000000     
    # 000       000  000      000                 000     000     000   000  000   000  000  000   000         
    # 000       000  0000000  0000000        0000000      000     000   000   0000000   000   000  00000000    
    
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
            
            @kali.palette = new Palette @kali
    
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (e)  => post.emit 'palette', 'proxy', @
    
    onMouseLeave: => log 'leave', @name
        
    onMouseEnter: => 
        
        super
        
        p = @pos()
        p = @kali.tools.stroke.pos() if @name == 'fill'
        
        post.emit 'palette', 'show', pos(60,0).plus p
        
        if not @kali.palette.proxy
            post.emit 'palette', 'proxy', @
    
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: () ->
                
        @top.style fill: @color
        @bot.style fill: @color, 'fill-opacity': @alpha
            
module.exports = Color

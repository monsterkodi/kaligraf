
#  0000000   0000000   000       0000000   00000000
# 000       000   000  000      000   000  000   000
# 000       000   000  000      000   000  0000000
# 000       000   000  000      000   000  000   000
#  0000000   0000000   0000000   0000000   000   000

{ empty, elem, drag, stopEvent, post, prefs, clamp, first, pos, log, $, _ } = require 'kxk'

{ itemIDs, colorGradient, grayGradient, checkersPattern } = require '../utils'

Tool    = require './tool'
Palette = require './palette'

class Color extends Tool

    constructor: (@kali, cfg) ->

        super @kali, cfg
        
        @stage.onColor = Color.onColor.bind @stage
        
        @svg = SVG(@element).size '100%', '100%'

        @g = @svg.group()

        @sqr = @g.rect()
        @bot = @g.rect()
        @top = @g.rect()

        @sqr.attr width:'100%', height:'100%', stroke: 'none', fill: checkersPattern(@svg, @kali.toolSize/6)
        @bot.attr width:'100%', height:'50%',  stroke: 'none', y:'50%'
        @top.attr width:'100%', height:'50%',  stroke: 'none'

        @bot.addClass 'trans'
        @top.addClass 'trans'
        @sqr.addClass 'trans'

        @copy prefs.get @name, luminance:0.5, color:'#fff', alpha:1, value:2/3, mode:'rgb'

        post.on 'palette', @onPalette

    set: (v) ->

        @copy v

        post.emit 'palette', 'proxy', @

    # 00000000    0000000   000      00000000  000000000  000000000  00000000
    # 000   000  000   000  000      000          000        000     000
    # 00000000   000000000  000      0000000      000        000     0000000
    # 000        000   000  000      000          000        000     000
    # 000        000   000  0000000  00000000     000        000     00000000

    createPalette: ->
        
        @kali.palette = new Palette @kali
        @kali.palette.setProxy @fill()
        
        post.on 'color', @stage.onColor
    
    onPalette: (action, value) =>

        if action == 'change' and value.proxy == @name

            @copy value

    copy: (v) ->

        @color     = new SVG.Color v.color if v.color?
        @luminance = v.luminance if v.luminance?
        @alpha     = v.alpha     if v.alpha?
        @value     = v.value     if v.value?
        @mode      = v.mode      if v.mode?

        prefs.set @name, luminance:@luminance, color:@color.toHex(), alpha:@alpha, value:@value, mode:@mode

        @update()

    # 00000000  000  000      000             0000000  000000000  00000000    0000000   000   000  00000000
    # 000       000  000      000            000          000     000   000  000   000  000  000   000
    # 000000    000  000      000            0000000      000     0000000    000   000  0000000    0000000
    # 000       000  000      000                 000     000     000   000  000   000  000  000   000
    # 000       000  0000000  0000000        0000000      000     000   000   0000000   000   000  00000000

    fill: ->  @kali.tools.getTool 'fill'
    initFill: ->
        fill = @fill()
        @element.appendChild fill.element
        fill.element.style.left   = "#{@kali.toolSize/6}px"
        fill.element.style.top    = "#{@kali.toolSize/6}px"
        fill.element.style.width  = "#{2*@kali.toolSize/3}px"
        fill.element.style.height = "#{2*@kali.toolSize/3}px"
    
    initChildren: ->

        super

        if @name == 'stroke'

            @initFill()
            @showChildren()
            @createPalette()

    hideChildren: -> post.emit 'palette', 'hide'
    
    #  0000000  000   000   0000000   00000000   
    # 000       000 0 000  000   000  000   000  
    # 0000000   000000000  000000000  00000000   
    #      000  000   000  000   000  000        
    # 0000000   00     00  000   000  000        
    
    swapColor: ->
        
        tmp =
            color:      @color
            luminance:  @luminance
            alpha:      @alpha
            value:      @value
            mode:       @mode
        
        fill = first @children
        @copy fill
        fill.copy tmp        

    #  0000000  000      000   0000000  000   000
    # 000       000      000  000       000  000
    # 000       000      000  000       0000000
    # 000       000      000  000       000  000
    #  0000000  0000000  000   0000000  000   000

    onClick: (event)  =>

        if @name == 'fill' and event.metaKey
            post.emit 'stage', 'setColor', @color, @alpha
            return

        if @kali.palette.proxy == @name
            other = @kali.tools.getTool @name == 'fill' and 'stroke' or 'fill'
            other.onClick event
            return

        post.emit 'palette', 'proxy', @

        if @name == 'fill'

            @element.style.left   = "#{@kali.toolSize/6}px"
            @element.style.top    = "#{@kali.toolSize/6}px"
            @element.style.width  = "#{2*@kali.toolSize/3}px"
            @element.style.height = "#{2*@kali.toolSize/3}px"

        else if @name == 'stroke'

            fill = first @children
            fill.element.style.left   = "#{@kali.toolSize/3}px"
            fill.element.style.top    = "#{@kali.toolSize/3}px"
            fill.element.style.width  = "#{@kali.toolSize/3}px"
            fill.element.style.height = "#{@kali.toolSize/3}px"

    onMouseLeave: => 

    onMouseEnter: (event) =>

        return if event.buttons
        
        if @name == 'fill' and @kali.tools.temp?.name == 'stroke'
            delete @kali.tools.temp
            tempStroke = true

        super

        p = @pos()

        if @name == 'fill'
            p = @kali.tools.stroke.pos()
            if tempStroke
                @kali.tools.temp = @kali.tools.stroke

        if @name == 'stroke'
            @kali.tools.temp = @

        post.emit 'palette', 'show', pos(@kali.toolSize,0).plus p

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

        
    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  
    
    @onColor: (color, prop, value) ->
        
        attr = {}
        
        switch prop
            when 'alpha'
                attr[color + '-opacity'] = value
            when 'color'
                attr[color] = new SVG.Color value
                
        items = @selectedNoTextItems()
        
        log 'selectedNoTextItems', items.length
        
        if empty items
             items = @selectedItems type:'text'
             log 'selectedTextItems', items.length
        
        if not empty(attr) and not empty(items)
            @do 'color' + itemIDs items
            for item in items
                item.style attr
                if prop == 'alpha'
                    item.node.removeAttribute 'opacity'
            @done()
        
module.exports = Color

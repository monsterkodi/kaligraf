
#  0000000   0000000   000       0000000   00000000
# 000       000   000  000      000   000  000   000
# 000       000   000  000      000   000  0000000
# 000       000   000  000      000   000  000   000
#  0000000   0000000   0000000   0000000   000   000

{ empty, elem, stopEvent, post, prefs, clamp, first, pos, log, $, _ } = require 'kxk'

{ itemIDs, itemGradient, colorGradient, grayGradient, gradientState, checkersPattern } = require '../utils'

Tool         = require './tool'
Palette      = require './palette'
GradientEdit = require './gradientedit'

class Color extends Tool

    constructor: (@kali, cfg) ->

        super @kali, cfg
                
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

        post.on 'palette',   @onPalette
        post.on 'selection', @onSelection

    set: (v) ->

        @copy v

        post.emit 'palette', 'proxy', @

    #  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000  
    # 000       000       000      000       000          000     000  000   000  0000  000  
    # 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000  
    #      000  000       000      000       000          000     000  000   000  000  0000  
    # 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000  
    
    onSelection: =>
        
        items = @stage.selectedLeafItems()
        return if empty items
        
        r = g = b = a = 0
        numColors = 0
        gradients = []
        
        for item in items
            color = item.style @name
            if color.startsWith 'url'
                gradient = itemGradient item, @name
                gradients.push gradient
            else
                numColors++
                color = new SVG.Color color
                a += parseFloat item.style "#{@name}-opacity"
                r += color.r
                g += color.g
                b += color.b
                    
        if numColors and empty gradients
            
            @alpha = a / numColors
            @color = new SVG.Color r:parseInt(r/numColors), g:parseInt(g/numColors), b:parseInt(b/numColors)
            @color = @color.toHex()      
            @gradient = false
            if @kali.palette.proxy == @name
                @kali.palette.setClosestColor @color, @alpha
                @set @kali.palette
            else
                @update()
            
        else if numColors == 0 and not empty gradients
            gradients = gradients.filter (g) -> not empty g
            states = gradients.map (g) -> s = gradientState g; s.id = g.id(); s
            states = _.uniqWith states, (a,b) -> _.isEqual a.stops, b.stops
            if states.length == 1
                # log states
                @alpha = 1
                @color = "url(\"##{first(states).id}\")"
                @gradient = true
                @update()
        
    # 00000000    0000000   000      00000000  000000000  000000000  00000000
    # 000   000  000   000  000      000          000        000     000
    # 00000000   000000000  000      0000000      000        000     0000000
    # 000        000   000  000      000          000        000     000
    # 000        000   000  0000000  00000000     000        000     00000000

    createPalette: ->
        
        @bindStage 'onColor'
        
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

    fill: ->  @kali.tool 'fill'
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
            other = @kali.tool @name == 'fill' and 'stroke' or 'fill'
            other.onClick event
            return

        post.emit 'palette', 'proxy', @
        
        if @gradient
            @showPalette()

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

    # 00000000  000   000  000000000  00000000  00000000   
    # 000       0000  000     000     000       000   000  
    # 0000000   000 0 000     000     0000000   0000000    
    # 000       000  0000     000     000       000   000  
    # 00000000  000   000     000     00000000  000   000  
    
    onMouseEnter: (event) =>

        return if event.buttons
        
        return if $(@element, '.toolHalo')?
        
        if @name == 'fill' and @kali.tools.temp?.name == 'stroke'
            delete @kali.tools.temp
            tempStroke = true

        super

        if @name == 'fill'
            if tempStroke
                @kali.tools.temp = @kali.tools.stroke

        if @name == 'stroke'
            @kali.tools.temp = @

        if not @kali.palette.proxy
            post.emit 'palette', 'proxy', @
            
        @showPalette()

    #  0000000  000   000   0000000   000   000  
    # 000       000   000  000   000  000 0 000  
    # 0000000   000000000  000   000  000000000  
    #      000  000   000  000   000  000   000  
    # 0000000   000   000   0000000   00     00  
    
    showPalette: -> 
        
        @kali.gradientEdit?.del()
        delete @kali.gradientEdit
        
        childPos = pos(@kali.toolSize,0).plus @kali.tools.stroke.pos()
        
        if @gradient
            
            color = @kali.tool @kali.palette.proxy 
            if not color?
                log 'dafuk?', @kali.palette.proxy
            @kali.gradientEdit = new GradientEdit @kali
            @kali.gradientEdit.setPos childPos
            @kali.gradientEdit.setGradient itemGradient color.top, 'fill'
        else
            post.emit 'palette', 'show', childPos
        
    hidePalette: ->
        
        if @gradient
            @kali.gradientEdit?.del()
            delete @kali.gradientEdit
        else
            post.emit 'palette', 'hide'
            
    childrenVisible: -> 
        
        if @gradient
            @kali.gradientEdit?.isVisible()
        else
            @kali.palette.isVisible()
    
    toggleChildren: -> 

        if @kali.palette.isVisible()
            @hideChildren()
        else
            @showPalette()

    showChildren: -> @showPalette()
    hideChildren: -> 
        
        @delHalo()
        @hidePalette()
                
    # 000   000  00000000   0000000     0000000   000000000  00000000
    # 000   000  000   000  000   000  000   000     000     000
    # 000   000  00000000   000   000  000000000     000     0000000
    # 000   000  000        000   000  000   000     000     000
    #  0000000   000        0000000    000   000     000     00000000

    update: ->
    
        @gradient = _.isString(@color) and @color.startsWith 'url'
        
        if @gradient
            @top.attr height:'100%'
            @bot.attr height:'0'
            @top.style fill: @color
            if @childrenVisible() then @showPalette()
        else
            @top.attr height:'50%'
            @bot.attr height:'50%'
            @top.style fill: @color
            @bot.style fill: @color, 'fill-opacity': @alpha
        
    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  
    
    onColor: (color, info) ->
        
        return if color not in ['fill', 'stroke']
        
        attr = {}

        switch info.prop
            when 'alpha'
                attr[color + '-opacity'] = info.alpha
            when 'color'
                attr[color] = new SVG.Color info.color
                
        items = @selectedNoTextItems()
        
        if empty items
             items = @selectedItems type:'text'
        
        if not empty(attr) and not empty(items)
            @do 'color' + itemIDs items
            for item in items
                item.style attr
                if info.prop == 'alpha'
                    item.node.removeAttribute 'opacity'
            @done()
        
module.exports = Color

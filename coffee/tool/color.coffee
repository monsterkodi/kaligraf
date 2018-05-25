
#  0000000   0000000   000       0000000   00000000
# 000       000   000  000      000   000  000   000
# 000       000   000  000      000   000  0000000
# 000       000   000  000      000   000  000   000
#  0000000   0000000   0000000   0000000   000   000

{ empty, elem, stopEvent, post, prefs, clamp, first, pos, log, $, _ } = require 'kxk'

{   itemIDs, itemGradient, colorGradient, grayGradient, gradientState, checkersPattern,
    cloneGradient, gradientUrl, urlGradient, setGradientStops } = require '../utils'

Tool         = require './tool'
Palette      = require './palette'
GradientEdit = require './gradientedit'

class Color extends Tool

    constructor: (kali, cfg) ->

        super kali, cfg
                
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

        @copy prefs.get @name, color:'#fff', alpha:1

        post.on 'palette',   @onPalette
        post.on 'gradient',  @onGradient
        post.on 'selection', @onSelection
        post.on 'edit',      @onSelection
        post.on 'fill',      @onFill

    set: (v) ->

        @copy v

        post.emit 'palette', 'proxy', @

    #  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  
    # 000        000   000  000   000  000   000  000  000       0000  000     000     
    # 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     
    # 000   000  000   000  000   000  000   000  000  000       000  0000     000     
    #  0000000   000   000  000   000  0000000    000  00000000  000   000     000     
    
    onGradient: (action, state) =>
        
        if action == 'changed'
            
            if state.name == @name or not state.name? and @name == @kali.activeColor
                @color = gradientUrl state.gradient
                @updateGradient()
                
            @kali.tool('gradient').postGradient stops:state.stops
            
        else if action == @name
            
            @onSelection()
        
    #  0000000  00000000  000      00000000   0000000  000000000  000   0000000   000   000  
    # 000       000       000      000       000          000     000  000   000  0000  000  
    # 0000000   0000000   000      0000000   000          000     000  000   000  000 0 000  
    #      000  000       000      000       000          000     000  000   000  000  0000  
    # 0000000   00000000  0000000  00000000   0000000     000     000   0000000   000   000  
    
    onSelection: =>
        
        @copyFromItems @stage.selectedLeafItems()
        
    copyFromItems: (items) ->
        
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
                state = first states 
                @alpha = 1
                @color = "url(\"##{state.id}\")"
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

        @color = new SVG.Color(v.color).toHex() if v.color?
        @alpha = v.alpha if v.alpha?

        @update()
        
    onFill: (info) =>
        
        return if @name != 'fill'
        
        @color = info.color.toHex()
        @alpha = info.alpha
                
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
        @kali.activeColor = 'fill'
    
    initChildren: ->

        super()

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

        if @kali.activeColor == @name
            other = @kali.tool @name == 'fill' and 'stroke' or 'fill'
            other.onClick event
            return

        @kali.activeColor = @name   
        @kali.tool('select').clickButton @name
        
        @showChildren()

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

        super()

        if @name == 'fill'
            if tempStroke
                @kali.tools.temp = @kali.tools.stroke

        if @name == 'stroke'
            @kali.tools.temp = @

        if @kali.activeColor != @name
            other = @kali.tool @name == 'fill' and 'stroke' or 'fill'
            other.showChildren()
        else
            @showChildren()

    #  0000000  000   000   0000000   000   000  
    # 000       000   000  000   000  000 0 000  
    # 0000000   000000000  000   000  000000000  
    #      000  000   000  000   000  000   000  
    # 0000000   000   000   0000000   00     00  
    
    childrenVisible: -> 
        
        if @gradient then @kali.gradientEdit?.isVisible() else @kali.palette?.isVisible()
    
    toggleChildren: -> 

        if @childrenVisible() then @hideChildren() else @showChildren()

    showChildren: -> 
        
        childPos = pos(@kali.toolSize,0).plus @kali.tools.stroke.pos()
        
        if @gradient
            
            if not @kali.gradientEdit?
                @hideChildren()
                gradient = itemGradient @top, 'fill' #<- must be fill!
                @kali.gradientEdit = new GradientEdit @kali, name:@name
                @kali.gradientEdit.setPos childPos
                @kali.gradientEdit.setGradient gradient
            
        else
            
            if not @kali.palette?.isVisible() or @kali.palette.proxy != @name
                @hideChildren()
                post.emit 'palette', 'proxy', @
                post.emit 'palette', 'show', childPos
    
    hideChildren: -> 
        
        @delHalo()
        
        @kali.gradientEdit?.del()
        delete @kali.gradientEdit

        post.emit 'palette', 'hide'
                
    # 000   000  00000000   0000000     0000000   000000000  00000000
    # 000   000  000   000  000   000  000   000     000     000
    # 000   000  00000000   000   000  000000000     000     0000000
    # 000   000  000        000   000  000   000     000     000
    #  0000000   000        0000000    000   000     000     00000000

    update: ->
            
        gradient = _.isString(@color) and @color.startsWith 'url'
        
        if @gradient != gradient
            visible = @childrenVisible()
            @hideChildren() if visible
            @gradient = gradient
        
        if @gradient
            @updateGradient()
        else
            @updateColor()
            if @kali.palette and @kali.palette.proxy != @name
                post.emit 'palette', 'proxy', @
            
        @showChildren() if visible

    updateGradient: ->
        
        state = gradientState urlGradient @color
        state.type = 'linear'
        gradient = @svg.gradient state.type
        setGradientStops gradient, state.stops
        
        @top.attr height:'100%'
        @bot.attr height:'0'
        @top.style fill: gradientUrl gradient

    updateColor: ->

        prefs.set @name, color:@color, alpha:@alpha
                
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

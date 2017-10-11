
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  
# 000        000   000  000   000  000   000  000  000       0000  000     000     
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     

{ prefs, post, empty, pos, log, _ } = require 'kxk'

{ itemIDs, itemGradient, setGradientState, gradientState } = require '../utils'

Tool         = require './tool'
GradientList = require './gradientlist'

SIZE = 13

class Gradient extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @initTitle()

        @state = prefs.get 'gradient', 
            type:           'none'
            spread:         'pad'
            stops:          []
            
        @state.spread ?= 'pad'
        
        @initButtons [
            name: 'none'
            tiny: 'gradient-none'
            choice: @state.type
            action: => @setType 'none'
        ,
            name: 'radial'
            tiny: 'gradient-radial'
            choice: @state.type
            action: => @setType 'radial'
        ,
            name: 'linear'
            tiny: 'gradient-linear'
            choice: @state.type
            action: => @setType 'linear'
        ]
        
        @initButtons [
            name: 'gradient'
            tiny: 'gradient'
            action: @toggleList
        ,
            name: 'repeat'
            tiny: 'gradient-repeat'
            choice: 'repeat'
            toggle: @state.spread == 'repeat'
            action: => @toggleSpread 'repeat'
        ,
            name: 'reflect'
            tiny: 'gradient-reflect'
            choice: 'reflect'
            toggle: @state.spread == 'reflect'
            action: => @toggleSpread 'reflect'
        ]
        
        @button('gradient').innerHTML = ''
        @svg = SVG(@button('gradient')).size SIZE,SIZE
        @svg.clear()
        
        @setState prefs.get 'gradient:state', type:'linear', stops:[
            offset: 0
            color:  "#000"
            opacity:1
        ,
            offset: 1
            color:  "#fff"
            opacity:1
        ]
        
        post.on 'gradient', @onGradient
        
        @setState @state

    #  0000000  000   000   0000000   000   000   0000000   00000000  0000000    
    # 000       000   000  000   000  0000  000  000        000       000   000  
    # 000       000000000  000000000  000 0 000  000  0000  0000000   000   000  
    # 000       000   000  000   000  000  0000  000   000  000       000   000  
    #  0000000  000   000  000   000  000   000   0000000   00000000  0000000    
    
    onGradient: (action, state) =>
        
        if action == 'changed' and not state.name
            @state.stops = _.cloneDeep state.stops
            @setState @state
            log 'postStops', @state.stops
            @postGradient stops:@state.stops
                
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  
    
    setState: (@state) ->

        @svg.clear()
        delete @gradient
        
        prefs.set 'gradient', @state
        
        return if @state.type == 'none' 
                        
        @gradient = @svg.gradient @state.type

        switch @state.type
            when 'radial'
                @state.from = pos 0.5, 0.5
                @state.to   = pos 0.5, 0.5
                switch @state.spread
                    when 'pad'
                        @state.r = 0.5
                    else
                        @state.r = 0.3
            when 'linear'
                delete @state.r
                switch @state.spread
                    when 'pad'
                        @state.from = pos 0.2, 0
                        @state.to   = pos 0.8, 0
                    else
                        @state.from = pos 0.0, 0
                        @state.to   = pos 0.5, 0
        
        setGradientState @gradient, @state
        
        @svg.rect(SIZE,SIZE).fill @gradient
        
    # 0000000     0000000   
    # 000   000  000   000  
    # 000   000  000   000  
    # 000   000  000   000  
    # 0000000     0000000   
    
    applyGradient: (style, info) ->
        
        items = @stage.selectedLeafItems()
        return if empty items
            
        @stage.do 'gradient'+itemIDs items
        
        for item in items
            if gradient = itemGradient item, style
                # log "applyGradient #{style} #{item.id()}", info
                if info.type?
                    @applyType item, style, info.type
                else
                    setGradientState gradient, info
            else if info.type? and info.type != 'none'
                @applyType item, style, info.type
        
        @stage.done()

    # 000000000  000   000  00000000   00000000  
    #    000      000 000   000   000  000       
    #    000       00000    00000000   0000000   
    #    000        000     000        000       
    #    000        000     000        00000000  
    
    setType: (type) =>
        
        @state.type = type
        @setState @state
        @postGradient type:type

    applyType: (item, style, type) ->
        
        # log 'Gradient.applyType', style, type
        
        if type == 'none'
                                
            if item.data(style)?
                item.style style, item.data style
            else
                @kali.tool(style).color
                
            if item.data("#{style}-opacity")?
                item.style "#{style}-opacity", item.data "#{style}-opacity"
            else
                @kali.tool(style).alpha
                                
        else
            
            if not item.data(style)?
                item.data style, item.style style
                
            if not item.data("#{style}opacity")?
                item.data "#{style}opacity", item.style "#{style}opacity"
            
            if gradient = itemGradient item, style
            
                return if gradient.type == type
            
                state = gradientState gradient
                state.type = type
                
                switch type 
                    when 'radial'
                        state.r = pos(state.from).dist pos(state.to)
                        state.radius = x:state.from.x+state.r, y:state.from.y
                        state.to = x:state.from.x, y:state.from.y
                    when 'linear'
                        state.to = x:state.radius.x, y:state.radius.y
                        delete state.r
                        delete state.radius
            else
                state = @state

            log "Gradient.applyType style:#{style} type:#{type} state:", state
                
            gradient = @stage.svg.gradient type
            setGradientState gradient, state
            
            log "Gradient.applyType id:#{gradient.id()} outer:", gradient.node.outerHTML
                
            item.style style, gradient                
            item.style "#{style}-opacity", 1
            log "Gradient.applyType ", item.style style
            log "Gradient.applyType ", item.style "#{style}-opacity"
            
                
        post.emit 'gradient', style, item:item, type:type
        
    # 000000000   0000000    0000000    0000000   000      00000000  
    #    000     000   000  000        000        000      000       
    #    000     000   000  000  0000  000  0000  000      0000000   
    #    000     000   000  000   000  000   000  000      000       
    #    000      0000000    0000000    0000000   0000000  00000000  
    
    toggleSpread: (spread) =>
        if spread == @state.spread
            @state.spread = 'pad'
        else
            @state.spread = spread
            
        repeat = @button 'repeat' 
        repeat.toggle = @state.spread == 'repeat'
        repeat.classList.toggle 'active', repeat.toggle
        
        reflect = @button 'reflect' 
        reflect.toggle = @state.spread == 'reflect'
        reflect.classList.toggle 'active', reflect.toggle
            
        log 'toggleSpread', spread, @state
        
        @setState @state
        @postGradient spread:@state.spread
        
    # 00000000    0000000    0000000  000000000  
    # 000   000  000   000  000          000     
    # 00000000   000   000  0000000      000     
    # 000        000   000       000     000     
    # 000         0000000   0000000      000     
    
    postGradient: (info) ->
        
        for style in ['fill', 'stroke']
            if @kali.tool('select').fillStroke.includes style
                post.emit 'gradient', style, info
                @applyGradient style, info
        
    # 000      000   0000000  000000000  
    # 000      000  000          000     
    # 000      000  0000000      000     
    # 000      000       000     000     
    # 0000000  000  0000000      000     
    
    toggleList: =>
        
        if @list? 
            @list.toggleDisplay()
        else
            @showList()
    
    showList: ->
        
        @list = new GradientList @kali
        @list.show()
        
module.exports = Gradient

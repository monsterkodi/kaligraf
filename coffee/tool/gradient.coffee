
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  
# 000        000   000  000   000  000   000  000  000       0000  000     000     
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     

{ prefs, post, empty, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool         = require './tool'
GradientList = require './gradientlist'

class Gradient extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
                
        @initTitle()

        @type = prefs.get 'gradient:type', 'none'
        
        @initButtons [
            name: 'none'
            tiny: 'gradient-none'
            choice: @type
            action: => @setType 'none'
        ,
            name: 'radial'
            tiny: 'gradient-radial'
            choice: @type
            action: => @setType 'radial'
        ,
            name: 'linear'
            tiny: 'gradient-linear'
            choice: @type
            action: => @setType 'linear'
        ]
        
        @initButtons [
            name: 'gradient'
            tiny: 'gradient'
            action: @toggleList
        ]
        @button('gradient').innerHTML = ''
        @svg = SVG(@button('gradient')).size 52, 18
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
        
        @setType @type

    onGradient: (state) =>
        
        state = _.clone state
        state.type = @state.type
        @setState state
                
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  
    
    setState: (@state) ->
        
        @svg.clear()
        
        if @state.type == 'none' 
            
            delete @gradient
            
        else            
            @gradient = @svg.gradient @state.type, (stop) =>
                for stp in @state.stops
                    stop.at stp.offset, stp.color, stp.opacity
    
            switch @state.type
                when 'radial'
                    @gradient.from 0.5,0.5
                    @gradient.to   0.5,0.5
                    @gradient.radius 0.5
                else
                    @gradient.from 0,0
                    @gradient.to   1,0
    
            @svg.rect(52,18).fill @gradient
        
        @doGradient()
        
    # 0000000     0000000   
    # 000   000  000   000  
    # 000   000  000   000  
    # 000   000  000   000  
    # 0000000     0000000   
    
    doGradient: ->
        
        items = @stage.selectedLeafItems()
        return if empty items
            
        @stage.do 'gradient'+itemIDs items
        
        if @state.type != 'none'
                                
            stageGradient = @stage.svg.gradient @state.type, (stop) =>
                for stp in @state.stops
                    stop.at stp.offset, stp.color, stp.opacity
            
        for item in items
            
            if @state.type == 'none'
                
                if @kali.tool('select').fillStroke.includes 'fill'
                
                    if item.data('fill')?
                        item.style 'fill', item.data 'fill'
                    else
                        @kali.tool('fill').color
                        
                    if item.data('fill-opacity')?
                        item.style 'fill-opacity', item.data 'fill-opacity'
                    else
                        @kali.tool('fill').alpha
                    
                if @kali.tool('select').fillStroke.includes 'stroke'
                    
                    if item.data('stroke')?
                        item.style 'stroke', item.data 'stroke'
                    else
                        @kali.tool('stroke').color
                        
                    if item.data('stroke-opacity')?
                        item.style 'stroke-opacity', item.data 'stroke-opacity'
                    else
                        @kali.tool('stroke').alpha
                    
            else
                
                if @kali.tool('select').fillStroke.includes 'fill'
                    
                    if not item.data('fill')?
                        item.data 'fill', item.style 'fill'
                        
                    if not item.data('fill-opacity')?
                        item.data 'fill-opacity', item.style 'fill-opacity'

                    item.style 
                        fill: stageGradient
                        'fill-opacity': 1
                        
                if @kali.tool('select').fillStroke.includes 'stroke'      
                    
                    if not item.data('stroke')?
                        item.data 'stroke', item.style 'stroke'
                        
                    if not item.data('stroke-opacity')?
                        item.data 'stroke-opacity', item.style 'stroke-opacity'
                        
                    item.style
                        stroke: stageGradient
                        'stroke-opacity': 1
                
        @stage.done()
        
    setType: (type) =>
        
        prefs.set 'gradient:type', type
        @state.type = type
        @setState @state
        
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

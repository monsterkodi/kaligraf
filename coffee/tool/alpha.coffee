###
 0000000   000      00000000   000   000   0000000   
000   000  000      000   000  000   000  000   000  
000000000  000      00000000   000000000  000000000  
000   000  000      000        000   000  000   000  
000   000  0000000  000        000   000  000   000  
###

{ post, empty, clamp, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool = require './tool'

class Alpha extends Tool

    constructor: (kali, cfg) ->
        
        super kali, cfg
        
        @initTitle()
        
        @initSpin
            name:   'alpha'
            min:    0
            max:    100
            reset:  [0,100]
            step:   [1,5,10,25]
            action: @setAlpha
            value:  100
            str: (value) -> parseInt value
                    
        post.on 'selection', @update
        post.on 'color',     @onColor
        @update()
    
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    onColor: (action, info) => 
        
        if info.prop == 'alpha'
            @enableSpin   'alpha'
            @setSpinValue 'alpha', info.alpha*100
    
    update: =>
        
        items = @stage.selectedLeafItems()
        if empty items
            @disableSpin 'alpha'
        else 
            @enableSpin   'alpha'
            @setSpinValue 'alpha', @alpha()*100
                        
    setAlpha: (alpha) => 
        
        alpha = alpha/100
        
        items = @stage.selectedLeafItems()
        return if empty items
        
        alpha = clamp 0, 1, alpha
        return if alpha == @alpha()
        
        @stage.do 'alpha'+itemIDs items
        for item in items
            if @kali.tool('select').fillStroke.includes 'stroke'
                item.style 'stroke-opacity': alpha
            if @kali.tool('select').fillStroke.includes 'fill'
                item.style 'fill-opacity': alpha
        @update()
        @stage.done()
        
    alpha: ->
        
        items = @stage.selectedLeafItems()
        return 1 if empty items
        
        alphas = []
        if @kali.tool('select').fillStroke.includes 'stroke'
            alphas = alphas.concat items.map (item) -> item.style 'stroke-opacity'
        if @kali.tool('select').fillStroke.includes 'fill'
            alphas = alphas.concat items.map (item) -> item.style 'fill-opacity'
            
        alphas = alphas.filter (a) -> a.length
        alpha = _.sumBy(alphas, (a) -> parseFloat a) / alphas.length
        alpha = Math.round(alpha*100)/100
        alpha
    
module.exports = Alpha


#  0000000   000      00000000   000   000   0000000   
# 000   000  000      000   000  000   000  000   000  
# 000000000  000      00000000   000000000  000000000  
# 000   000  000      000        000   000  000   000  
# 000   000  0000000  000        000   000  000   000  

{ prefs, clamp, empty, first, post, pos, log, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool = require './tool'

class Alpha extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @initTitle()
        
        @initSpin
            name:   'alpha'
            min:    0
            max:    100
            reset:  [0,100]
            step:   [1,5,10,25]
            action: @setAlpha
            
        @initButtons [
            small:  'alpha-fill'
            name:   'fill'
            toggle: prefs.get 'alpha:fill', true
            action: => prefs.set 'alpha:fill', @button('fill').toggle; @update()
        ,
            small:  'alpha-stroke'
            name:   'stroke'
            toggle: prefs.get 'alpha:stroke', true
            action: => prefs.set 'alpha:stroke', @button('stroke').toggle; @update()
        ]
        
        post.on 'selection', @update
        @update()
    
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: =>
        
        items = @stage.selectedLeafItems()
        if empty(items) or not (@button('stroke').toggle or @button('fill').toggle)
            
            @hideButton 'alpha minus'
            @hideButton 'alpha reset'
            @hideButton 'alpha plus'
        else 
            alpha = @alpha()
            @showButton 'alpha minus', alpha > 0
            @showButton 'alpha reset'
            @showButton 'alpha plus', alpha < 1
            
            @button('alpha reset').innerHTML = parseInt alpha*100
            @button('alpha reset').spin.value = alpha*100
                        
    setAlpha: (alpha) => 
        
        alpha = alpha/100
        
        items = @stage.selectedLeafItems()
        return if empty items
        
        alpha = clamp 0, 1, alpha
        return if alpha == @alpha()
        
        @stage.do 'alpha'+itemIDs items
        for item in items
            if @button('stroke').toggle
                item.style 'stroke-opacity': alpha
            if @button('fill').toggle
                item.style 'fill-opacity': alpha
        @update()
        @stage.done()
        
    alpha: ->
        
        items = @stage.selectedLeafItems()
        return 1 if empty items
        
        alphas = []
        if @button('stroke').toggle
            alphas = alphas.concat items.map (item) -> item.style 'stroke-opacity'
        if @button('fill').toggle
            alphas = alphas.concat items.map (item) -> item.style 'fill-opacity'
            
        alphas = alphas.filter (a) -> a.length
        alpha = _.sumBy(alphas, (a) -> parseFloat a) / alphas.length
        alpha = Math.round(alpha*100)/100
        alpha
    
module.exports = Alpha

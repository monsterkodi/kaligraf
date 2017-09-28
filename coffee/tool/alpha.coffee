
#  0000000   000      00000000   000   000   0000000   
# 000   000  000      000   000  000   000  000   000  
# 000000000  000      00000000   000000000  000000000  
# 000   000  000      000        000   000  000   000  
# 000   000  0000000  000        000   000  000   000  

{ clamp, empty, first, post, pos, log, _ } = require 'kxk'

Tool = require './tool'

class Alpha extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @initTitle()
        
        @initButtons [
            text:   '<'
            name:   'minus'
            action: @onMinus
        ,
            text:   '0'
            name:   'reset'
            action: @onReset
        , 
            text:   '>'
            name:   'plus'
            action: @onPlus
        ]
        @initButtons [
            small:  'alpha-fill'
            name:   'fill'
            toggle: true
            action: @onFill
        ,
            small:  'alpha-stroke'
            name:   'stroke'
            toggle: true
            action: @onStroke
        ]
        
        post.on 'selection', @update
        @update()
    
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: =>
        log @button('stroke').toggle
        log @button('fill').toggle
        
        items = @stage.selectedItems()
        if empty(items) or not (@button('stroke').toggle or @button('fill').toggle)
            
            @hideButton 'minus'
            @hideButton 'reset'
            @hideButton 'plus'
        else 
            alpha = @alpha()
            @showButton 'minus', alpha > 0
            @showButton 'reset'
            @showButton 'plus', alpha < 1
            
            @button('reset').innerHTML = parseInt alpha*100
                        
    onReset: => @setAlpha @alpha() != 1 and 1 or 0
    onMinus: => @setAlpha @alpha() - 0.05
    onPlus:  => @setAlpha @alpha() + 0.05
    
    onStroke: => @update()
    onFill:   => @update()
    
    setAlpha: (alpha) -> 
        
        items = @stage.selectedItems()
        return if empty items
        
        alpha = clamp 0, 1, alpha
        return if alpha == @alpha()
        
        @stage.do()
        for item in items
            if @button('stroke').toggle
                item.style 'stroke-opacity': alpha
            if @button('fill').toggle
                item.style 'fill-opacity': alpha
        @update()
        @stage.done()
        
    alpha: -> 
        
        alphas = []
        items  = @stage.selection.items
        if @button('stroke').toggle
            alphas = alphas.concat items.map (item) -> item.style 'stroke-opacity'
        if @button('fill').toggle
            alphas = alphas.concat items.map (item) -> item.style 'fill-opacity'
        _.sumBy(alphas, (a) -> parseFloat a) / alphas.length
    
module.exports = Alpha

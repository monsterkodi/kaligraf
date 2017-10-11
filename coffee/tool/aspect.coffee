
#  0000000    0000000  00000000   00000000   0000000  000000000  
# 000   000  000       000   000  000       000          000     
# 000000000  0000000   00000000   0000000   000          000     
# 000   000       000  000        000       000          000     
# 000   000  0000000   000        00000000   0000000     000     

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs, growBox, boxOffset, bboxForItems, scaleBox, moveBox } = require '../utils'

Tool = require './tool'

class Aspect extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @ratio  = prefs.get 'aspect:ratio',  1
        @locked = prefs.get 'aspect:locked', false
        
        post.on 'stage', @onStage
        post.on 'undo',  @onUndo
        
        @initTitle()
        
        @initSpin
            name:   'ratio'
            min:    0.01
            max:    100
            reset:  1
            speed:  0.01
            step:   [0.01,0.05,0.1,0.5]
            action: @update
            value:  @ratio
            str: (value) -> value.toFixed 2
            
        @initButtons [
            name:   'lock'
            tiny:   'aspect-lock'
            toggle: @locked
            action: @onLock
        ]
        
    onLock: =>
        
        @locked = @button('lock').toggle
        prefs.set 'aspect:locked', @locked
        @update()
        
    # 00000000    0000000   000000000  000   0000000   
    # 000   000  000   000     000     000  000   000  
    # 0000000    000000000     000     000  000   000  
    # 000   000  000   000     000     000  000   000  
    # 000   000  000   000     000     000   0000000   
            
    updateRatio: ->
        
        return if @locked
        paddingBox = @stage.paddingViewBox()
        @setRatio paddingBox.height and paddingBox.width/paddingBox.height or 0
        
    setRatio: (@ratio) => @setSpinValue 'ratio', @ratio
    
    update: =>
        
        aspect = @getSpin 'ratio' 
        @ratio = aspect.value
        prefs.set 'aspect:ratio', @ratio
        aspect.value = @ratio
        post.emit 'aspect', ratio:@ratio, locked:@locked
    
    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  

    onUndo: (info) =>
        if info.action == 'done' 
            @updateRatio()
    
    onStage: (action, info) =>
        switch action
            when 'viewbox', 'load' 
                @updateRatio()
                
module.exports = Aspect

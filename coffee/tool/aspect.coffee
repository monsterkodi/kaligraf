
#  0000000    0000000  00000000   00000000   0000000  000000000  
# 000   000  000       000   000  000       000          000     
# 000000000  0000000   00000000   0000000   000          000     
# 000   000       000  000        000       000          000     
# 000   000  0000000   000        00000000   0000000     000     

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs, growBox, boxOffset, scaleBox, moveBox } = require '../utils'

Tool = require './tool'

class Aspect extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @ratio  = 1
        @locked = false
        
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
            action: @onRatio
            value:  @ratio
            str: (value) -> value.toFixed 2
            
        @initButtons [
            name:   'lock'
            tiny:   ['aspect-lock', 'aspect-locked']
            toggle: @locked
            action: @onLock
        ]
        
    onLock: =>
        
        @stage.do 'aspect'
        @locked = @button('lock').toggle
        @update()
        @stage.done()
      
    onRatio: =>
        
        @stage.do 'aspect'
        @update()
        @stage.done()

    state: ->
        
        locked: @locked
        ratio:  @ratio
        
    restore: (state) -> 

        @locked = state.locked
        @ratio  = state.ratio
        @setSpinValue 'ratio', @ratio
        @setToggle    'lock',  @locked
        
    # 00000000    0000000   000000000  000   0000000   
    # 000   000  000   000     000     000  000   000  
    # 0000000    000000000     000     000  000   000  
    # 000   000  000   000     000     000  000   000  
    # 000   000  000   000     000     000   0000000   
            
    updateRatio: ->
        
        return if @locked
        paddingBox = @stage.paddingBox()
        @setRatio paddingBox.height and paddingBox.width/paddingBox.height or 0
        
    setRatio: (@ratio) => @setSpinValue 'ratio', @ratio
    
    update: =>
        
        aspect = @getSpin 'ratio' 
        @ratio = aspect.value
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
        
        if action == 'load' and info.viewbox
            
            box = @stage.layerBox()
            growBox box, @kali.tool('padding').percent
           
            diffX = Math.abs(info.viewbox.width  - box.width)/box.width
            diffY = Math.abs(info.viewbox.height - box.height)/box.height
            @locked = diffX > 0.02 or diffY > 0.02

            @setToggle 'lock', @locked
            @setRatio info.viewbox.width / info.viewbox.height
                
module.exports = Aspect

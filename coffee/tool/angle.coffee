
#  0000000   000   000   0000000   000      00000000  
# 000   000  0000  000  000        000      000       
# 000000000  000 0 000  000  0000  000      0000000   
# 000   000  000  0000  000   000  000      000       
# 000   000  000   000   0000000   0000000  00000000  

{ clamp, empty, first, post, pos, log, _ } = require 'kxk'

Tool = require './tool'

class Angle extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @initTitle()
        
        @initSpin 
            name:   'angle'
            min:    -180
            max:    +180
            reset:  0
            step:   [1,5,15,45]
            wrap:   true
            value:  0
            str:    (value) -> "#{value}°"
            action: (a) => @stage.resizer.setAngle a
        
        post.on 'resizer',   @update
        post.on 'selection', @update
    
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: =>
        
        if @stage.selection.empty()
            
            @disableSpin 'angle'
        else
            @enableSpin 'angle'
                        
            @angle = Math.round @stage.resizer.angle()
            @setSpinValue 'angle', @angle
        
module.exports = Angle

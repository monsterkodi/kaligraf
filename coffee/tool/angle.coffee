
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
        
        @initButtons [
            text:   '0'
            name:   'reset'
            action: @onReset
        ]
        @initButtons [
            text:   '<'
            name:   'ccw'
            action: @onCCW
        ,
            text:   '>'
            name:   'cw'
            action: @onCW
        ]
        
        post.on 'resizer',   @update
        post.on 'selection', @update
    
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: =>
        
        if @stage.selection.empty()
            
            @hideButton 'reset'
            @hideButton 'ccw'
            @hideButton 'cw'
        else
            @showButton 'reset'
            @showButton 'ccw'
            @showButton 'cw'
                        
            @angle = Math.round @stage.resizer.angle()

            @button('reset').innerHTML = @angle
        
    onReset: => @stage.resizer.setAngle 0
    onCCW:   => @stage.resizer.addAngle -1
    onCW:    => @stage.resizer.addAngle +1
    
module.exports = Angle

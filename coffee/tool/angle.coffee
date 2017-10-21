
#  0000000   000   000   0000000   000      00000000  
# 000   000  0000  000  000        000      000       
# 000000000  000 0 000  000  0000  000      0000000   
# 000   000  000  0000  000   000  000      000       
# 000   000  000   000   0000000   0000000  00000000  

{ clamp, empty, first, post, pos, log, _ } = require 'kxk'

{ boxCenter } = require '../utils'

Tool  = require './tool'
Mover = require '../edit/mover'

class Angle extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @trans = @kali.trans
        
        @initTitle()
        
        @initSpin 
            name:   'angle'
            min:    -360
            max:    +360
            reset:  0
            step:   [1,5,15,45]
            wrap:   true
            value:  0
            str:    (value) -> "#{value}°"
            action: (a) => @stage.resizer.setAngle a
            
        @initButtons [
            name:   'apply'
            tiny:   'angle-apply'
            action: @onApply
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
            
            @disableSpin 'angle'
        else
            @enableSpin 'angle'
                        
            @angle = Math.round @stage.resizer.angle()
            @angle -= 360 while @angle > 360
            @angle += 360 while @angle < -360
            @setSpinValue 'angle', @angle
        
    onApply: =>
        
        @stage.do 'apply'
        for item in @stage.selectedLeafItems()
            if item.transform().rotation

                angle = item.transform().rotation
                    
                rectCenter = @trans.transform item, boxCenter item.bbox()
                item.transform new SVG.Matrix()
                @trans.setCenter item, rectCenter
                
                boxcntr = boxCenter item.bbox()
                transmat = new SVG.Matrix().around boxcntr.x, boxcntr.y, new SVG.Matrix().rotate angle
                mover = new Mover item:item, kali:@kali
                
                continue if not mover.isPath()
                
                rotDot = (index, dot) ->
                    dotPos = mover.posAt index, dot
                    newPos = pos new SVG.Point(dotPos).transform transmat
                    mover.setDotPos dot, index, newPos
                
                for index in [0...mover.numPoints()]
                    rotDot index, 'point'
                    point = mover.pointAt index
                    switch point[0]
                        when 'S' 
                            rotDot index, 'ctrls'
                        when 'C'
                            rotDot index, 'ctrl1'
                            rotDot index, 'ctrl2'
                        when 'Q'
                            rotDot index, 'ctrlq'
                    
                item.plot mover.points()   
                
        @stage.selection.update()
        @stage.resizer.update()
        @stage.done()
        @update()
            
module.exports = Angle

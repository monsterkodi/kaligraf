
# 00000000    0000000   0000000    0000000    000  000   000   0000000   
# 000   000  000   000  000   000  000   000  000  0000  000  000        
# 00000000   000000000  000   000  000   000  000  000 0 000  000  0000  
# 000        000   000  000   000  000   000  000  000  0000  000   000  
# 000        000   000  0000000    0000000    000  000   000   0000000   

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs, growBox, boxOffset, bboxForItems, scaleBox, moveBox } = require '../utils'

Tool = require './tool'

class Padding extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @selection = @stage.selection
        
        @percent = prefs.get 'padding:percent', 10
        @visible = prefs.get 'padding:visible', false
        
        post.on 'stage', @onStage
        post.on 'undo',  @onUndo
        
        @initTitle()
        
        @initSpin
            name:   'percent'
            min:    0
            max:    100
            reset:  [0,10]
            step:   [1,5,10,25]
            action: @setPercent
            value:  @percent
            str:    (value) -> "#{value}%"
            
        @initButtons [
            name:   'show'
            tiny:   'padding-show'
            toggle: @visible
            action: @onShow
        ]
        
        @showPadding() if @visible
       
    onStage: (action, info) =>
        switch action
            when 'viewbox' then @update()
            when 'load' 
                if info.viewbox?
                    bb = bboxForItems @stage.items()
                    percentX = (info.viewbox.width  / bb.width  - 1) * 50
                    percentY = (info.viewbox.height / bb.height - 1) * 50
                    @setPercent parseInt Math.min percentX, percentY
                    @setSpinValue 'percent', @percent
                else
                    @update()
        
    onUndo: (info) =>
        if info.action == 'done' then @update()
        
    setPercent: (@percent) =>

        prefs.set 'padding:percent', @percent
        @update()
        
    onShow: =>
        
        @visible = @button('show').toggle
        
        prefs.set 'padding:visible', @visible
            
        if @visible then @showPadding()
        else             @hidePadding()
        
    showPadding: ->
        
        if not @rect?
            @rect = @selection.addRect()
            @rect.classList.add 'paddingRect'
        @update()
        
    update: =>
        
        return if not @rect?
        
        bb = bboxForItems @stage.items() 
        growBox bb, @percent
        moveBox bb, boxOffset(@stage.svg.viewbox()).times -1
        scaleBox bb, @stage.zoom
        @selection.setRect @rect, bb
     
    hidePadding: -> 
        
        @rect?.remove()
        delete @rect
        
module.exports = Padding

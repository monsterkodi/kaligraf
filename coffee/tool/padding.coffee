
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
        
        @show() if @visible
       
    onStage: (action) => 
        if action in ['viewbox', 'load'] then @update()
        
    onUndo: (info) =>
        if info.action == 'done' then @update()
        
    setPercent: (@percent) =>
        
        prefs.set 'padding:percent', @percent
        @update()
        
    onShow: =>
        
        @setVisible @button('show').toggle
        
    setVisible: (@visible) ->
          
        prefs.set 'padding:visible', @visible
            
        if @visible then @show()
        else             @hide()
        
    show: ->
        
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
     
    hide: -> 
        
        @rect?.remove()
        delete @rect
        
module.exports = Padding

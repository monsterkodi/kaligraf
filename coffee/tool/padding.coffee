
# 00000000    0000000   0000000    0000000    000  000   000   0000000   
# 000   000  000   000  000   000  000   000  000  0000  000  000        
# 00000000   000000000  000   000  000   000  000  000 0 000  000  0000  
# 000        000   000  000   000  000   000  000  000  0000  000   000  
# 000        000   000  0000000    0000000    000  000   000   0000000   

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs, growBox, boxOffset, bboxForItems, scaleBox, moveBox, setBox } = require '../utils'

Tool = require './tool'

class Padding extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @selection = @stage.selection
        
        @percent = prefs.get 'padding:percent', 10
        @visible = prefs.get 'padding:visible', false
        
        @bindStage ['paddingBox', 'layerBox', 'paddingViewBox']
        
        post.on 'stage',  @onStage
        post.on 'undo',   @onUndo
        post.on 'aspect', @update
        
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
        
    onUndo: (info) =>
        if info.action == 'done' then @update()
        
    setPercent: (@percent) =>

        @stage.do 'padding'
        if _.isNaN @percent then @percent = 0
        prefs.set 'padding:percent', @percent
        @update()
        @stage.done()
       
    state: ->
        
        visible: @visible
        percent: @percent
        
    restore: (state) -> 

        @percent = state.percent
        @visible = state.visible
        @setSpinValue 'percent', @percent
        @setToggle 'show', @visible
        @update()
        
    #  0000000  000   000   0000000   000   000  
    # 000       000   000  000   000  000 0 000  
    # 0000000   000000000  000   000  000000000  
    #      000  000   000  000   000  000   000  
    # 0000000   000   000   0000000   00     00  
    
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
        
    hidePadding: -> 
        
        @rect?.remove()
        delete @rect

    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: =>
        
        return @hidePadding() if not @visible
        
        paddingBox = @stage.paddingViewBox()
            
        return @hidePadding() if paddingBox.width == 0 or paddingBox.height == 0
        
        @showPadding() if not @rect?
        
        @selection.setRect @rect, paddingBox

    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  
    
    onStage: (action, info) =>
        
        switch action
            
            when 'viewbox' then @update()
            when 'load' 
                if info.viewbox?
                    bb = bboxForItems @stage.items()
                    percentX = (info.viewbox.width  / bb.width  - 1) * 50
                    percentY = (info.viewbox.height / bb.height - 1) * 50
                    @percent = parseInt Math.min percentX, percentY
                    @setSpinValue 'percent', @percent
                else
                    @update()

    # 0000000     0000000   000   000  
    # 000   000  000   000   000 000   
    # 0000000    000   000    00000    
    # 000   000  000   000   000 000   
    # 0000000     0000000   000   000  
    
    layerBox: ->
    
        for index in [0...Math.max(1, @numLayers())]
            @layerAt(index).show()
            
        box = bboxForItems @items()

        for index in [0...Math.max(1, @numLayers())]
            layer = @layerAt index 
            layer.hide() if layer.data 'hidden'
        box
        
    paddingBox: ->

        box = @layerBox() 
        growBox box, @kali.tool('padding').percent
        
        aspect = @kali.tool 'aspect' 
        if aspect.locked
            paddingRatio = box.width / box.height
            if paddingRatio > aspect.ratio
                setBox box, 'height', box.width / aspect.ratio
            else 
                setBox box, 'width', box.height * aspect.ratio
        box
        
    paddingViewBox: ->
        
        box = @paddingBox()
        moveBox box, boxOffset(@svg.viewbox()).times -1
        scaleBox box, @zoom
        box
        
module.exports = Padding

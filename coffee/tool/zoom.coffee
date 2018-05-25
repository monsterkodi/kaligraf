###
0000000   0000000    0000000   00     00  
   000   000   000  000   000  000   000  
  000    000   000  000   000  000000000  
 000     000   000  000   000  000 0 000  
0000000   0000000    0000000   000   000  
###

{ clamp, elem, empty, post, pos, log, _ } = require 'kxk'

{ rboxForItems, bboxForItems, boxCenter, moveBox, zoomBox, scaleBox } = require '../utils'

Tool = require './tool'

class Zoom extends Tool

    constructor: (kali, cfg) ->
        
        super kali, cfg
        
        @bindStage ['centerSelection', 'zoomAtPos', 'setZoom', 'toolCenter', 'resetZoom']
        
        @initTitle()
        
        @initButtons [
            text:   'x1'
            name:   'reset'
            action: @zoomReset
        ]
        @initButtons [
            text:   '-'
            name:   'out'
            action: @zoomOut
        ,
            text:   'O'
            name:   'center'
            action: @center
        ,
            text:   '+'
            name:   'in'
            action: @zoomIn
        ]
        
        post.on 'stage', @onStage
    
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  

    @levels = [
        0.01, 0.02, 0.05,
        0.10, 0.15, 0.20, 0.25, 0.33, 0.50, 0.75,
        1, 1.5, 2, 3, 4, 5, 6, 8,
        10, 15, 20, 40, 80,
        100, 150, 200, 400, 800,
        1000
    ]
    
    zoomReset: => @stage.setZoom 1, @stage.toolCenter 1

    zoomIn: (event) => 
        
        for i in [0...Zoom.levels.length]
            if @stage.zoom < Zoom.levels[i]
                @stage.setZoom Zoom.levels[i], @stage.stageCenter()
                return
    
    zoomOut: (event) =>
        
        for i in [Zoom.levels.length-1..0]
            if @stage.zoom > Zoom.levels[i]
                @stage.setZoom Zoom.levels[i], @stage.stageCenter()
                return

    center: (event) =>
        
        @stage.centerSelection()
                                
    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  
    
    onStage: (action, value) =>
        
        switch action
            when 'zoom'
                btn = @button 'reset' 
                if value < 1
                    btn.innerHTML = "#{parseInt value*100}%"
                else if value < 1.1
                    btn.innerHTML = "x1"
                else if value < 2
                    btn.innerHTML = "x#{parseInt value}.#{parseInt(value*10) % 10}"
                else
                    btn.innerHTML = "x#{parseInt value}"

    #  0000000  00000000  000   000  000000000  00000000  00000000   
    # 000       000       0000  000     000     000       000   000  
    # 000       0000000   000 0 000     000     0000000   0000000    
    # 000       000       000  0000     000     000       000   000  
    #  0000000  00000000  000   000     000     00000000  000   000  

    centerSelection: ->

        items = @selectedOrAllItems()
        
        if @shapes.text?
            items = [@shapes.text.item]
        
        if empty items
            @centerAtStagePos @toolCenter @zoom
            return

        list = @kali.tool('layer').list
        
        lv = list?.isVisible()
        lw = lv and list.element.getBoundingClientRect().width or 0
        
        b = rboxForItems items, @viewPos()
        v = @viewSize()
        v.x -= 60 + lw
        w = (b.w / @zoom) /  v.x
        h = (b.h / @zoom) /  v.y
        percent = @kali.tool('padding').percent
        w *= 1+2*percent/100
        h *= 1+2*percent/100
        z = 1 / Math.max(w, h)
        
        @setZoom z
        
        c = boxCenter bboxForItems items
        v.x += 120
        o = c.minus v.times 0.5/z
        
        @setViewBox 
            x:      o.x
            y:      o.y
            width:  @viewSize().x/@zoom
            height: @viewSize().y/@zoom
        
    # 00000000   00000000   0000000  00000000  000000000  
    # 000   000  000       000       000          000     
    # 0000000    0000000   0000000   0000000      000     
    # 000   000  000            000  000          000     
    # 000   000  00000000  0000000   00000000     000     
    
    resetZoom: => @setZoom 1, @toolCenter 1

    #  0000000  00000000  000000000  0000000   0000000    0000000   00     00  
    # 000       000          000        000   000   000  000   000  000   000  
    # 0000000   0000000      000       000    000   000  000   000  000000000  
    #      000  000          000      000     000   000  000   000  000 0 000  
    # 0000000   00000000     000     0000000   0000000    0000000   000   000  
    
    setZoom: (z, sc) ->

        z = clamp 0.01, 1000, z

        @zoom = z
        
        @resetSize()
        @centerAtStagePos sc if sc?

    # 0000000   0000000    0000000   00     00   0000000   000000000  
    #    000   000   000  000   000  000   000  000   000     000     
    #   000    000   000  000   000  000000000  000000000     000     
    #  000     000   000  000   000  000 0 000  000   000     000     
    # 0000000   0000000    0000000   000   000  000   000     000     
    
    zoomAtPos: (viewPos, stagePos, factor) ->

        @zoom = clamp 0.01, 1000, @zoom * factor
        
        delta = viewPos.minus @viewForStage stagePos
        delta.scale -1.0/@zoom
        
        box = @svg.viewbox()
        
        box.width  = @viewSize().x / @zoom
        box.height = @viewSize().y / @zoom
        box.x += delta.x
        box.y += delta.y

        @setViewBox box

    toolCenter: (zoom) ->

        vc = @viewCenter()
        vc.x = 560.5 if @viewSize().x > 1120
        vc.minus(pos(@kali.toolSize+0.5,@kali.toolSize/2+0.5)).scale(1/zoom)
        
module.exports = Zoom

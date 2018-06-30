###
000       0000000   000   000  00000000   00000000  
000      000   000  000   000  000   000  000       
000      000   000  000   000  00000000   0000000   
000      000   000  000   000  000        000       
0000000   0000000    0000000   000        00000000  
###

{ pos, log, _ } = require 'kxk'

Tool = require './tool' 
 
class Loupe extends Tool

    constructor: (kali, cfg) ->

        super kali, cfg
        
        @tools     = @kali.tools
        @selection = @stage.selection
        
        @bindStage 'loupe'
        
    # 0000000     0000000   000   000  000   000  
    # 000   000  000   000  000 0 000  0000  000  
    # 000   000  000   000  000000000  000 0 000  
    # 000   000  000   000  000   000  000  0000  
    # 0000000     0000000   00     00  000   000  
    
    onMove: (event) => @stage.setToolCursor @tools.shiftDown and 'zoom-out' or 'zoom-in'
    
    onStageDown: (event) =>
        
        @rect ?= @selection.addRect()

    onStageDrag: (drag, event) =>
        
        r = @stage.offsetRect x:drag.startPos.x, y:drag.startPos.y, x2:drag.pos.x, y2:drag.pos.y                
        @selection.setRect @rect, r
                
    onStageStop: (drag, event) =>
        
        if @rect?
            @rect.remove()
            delete @rect
        @stage.loupe drag.startPos, drag.pos
        @stage.setToolCursor @tools.shiftDown and 'zoom-out' or 'zoom-in'

    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  

    loupe: (p1, p2) ->

        viewPos1 = @viewForEvent pos p1
        viewPos2 = @viewForEvent pos p2
        viewPos  = viewPos1.mid viewPos2

        sc = @stageForView viewPos

        sd = @stageForView(viewPos1).sub @stageForView(viewPos2)
        dw = Math.abs sd.x
        dh = Math.abs sd.y

        if dw == 0 or dh == 0
            out = @kali.tools.shiftDown
            @zoomAtPos viewPos, sc, out and 0.75 or 1.25
            return
        else
            vb = @svg.viewbox()
            zw = vb.width  / dw
            zh = vb.height / dh
            z = Math.min zw, zh

        if out then z = 1.0/z

        @setZoom @zoom * z, sc
        
module.exports = Loupe

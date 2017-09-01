
#  0000000  000000000   0000000    0000000   00000000  
# 000          000     000   000  000        000       
# 0000000      000     000000000  000  0000  0000000   
#      000     000     000   000  000   000  000       
# 0000000      000     000   000   0000000   00000000  

{ resolve, elem, post, drag, stopEvent, last, clamp, pos, fs, log, _ } = require 'kxk'

{ growBox, normRect, boxForItems, boxOffset, boxCenter } = require './utils'

{ clipboard } = require 'electron'

SVG       = require 'svg.js'
clr       = require 'svg.colorat.js'
Shapes    = require './shapes'
Selection = require './selection'
Resizer   = require './resizer'

class Stage

    constructor: (@kali) ->

        @element = elem 'div', id: 'stage'
        @kali.element.insertBefore @element, @kali.element.firstChild
        @svg = SVG(@element).size '100%', '100%' 
        @svg.addClass 'stageSVG'
        @svg.clear()
        
        @kali.stage = @
        
        @selection = new Selection @kali
        @resizer   = new Resizer   @kali
        @shapes    = new Shapes    @kali
        
        @drag = new drag
            target:  @element
            onStart: @shapes.onStart
            onMove:  @shapes.onMove
            onStop:  @shapes.onStop

        @element.addEventListener 'wheel', @onWheel
        window.area.on 'resized', @onResize

        @zoom = 1
        @resetView()

    # 000  000000000  00000000  00     00  
    # 000     000     000       000   000  
    # 000     000     0000000   000000000  
    # 000     000     000       000 0 000  
    # 000     000     00000000  000   000  
    
    itemAtPos: (p) ->
        
        e = document.elementsFromPoint p.x, p.y
        for i in e
            if i.instance? and i != @svg and i.instance in @svg.children()
                return i.instance

    items: ->
        @svg.children().filter (child) ->
            if child.type != 'g' and child.id()?.startsWith 'SvgjsG'
                log 'skip group', child.id()
                return false
            if child.type == 'defs'
                return false
            true
                
    #  0000000  000   000   0000000   
    # 000       000   000  000        
    # 0000000    000 000   000  0000  
    #      000     000     000   000  
    # 0000000       0       0000000   
    
    setSVG: (svg) ->
        
        @clear()
        @addSVG svg, select:false
        @resetView()
        
    addSVG: (svg, opt) ->
        
        e = elem 'div'
        e.innerHTML = svg
        
        if e.firstChild.tagName == 'svg'

            svg = SVG.adopt e.firstChild
            if svg? and svg.children().length
                
                @selection.clear()
                
                for child in svg.children()
                    @svg.svg child.svg()
                    added = last @svg.children() 
                    if added.type != 'defs' and opt?.select != false
                        @selection.add last @svg.children() 

    getSVG: (items, bb) ->
        
        selected = _.clone @selection.items
        @selection.clear()
        
        svgStr = '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" version="1.1" style="stroke-linecap: round; stroke-linejoin: round;" '
        svgStr += "viewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        for item in items
            svgStr += item.svg()
        svgStr += '</svg>'
        
        for item in selected
            @selection.add item
        
        svgStr
                    
    #  0000000   0000000   00000000   000   000  
    # 000       000   000  000   000   000 000   
    # 000       000   000  00000000     00000    
    # 000       000   000  000           000     
    #  0000000   0000000   000           000     
    
    copy: -> 
        
        selected = _.clone @selection.items
        items = @selection.empty() and @items() or selected
        return if items.length <= 0
        
        @selection.clear()
        
        bb = boxForItems items, @viewPos()
        growBox bb
        
        svg = @getSVG items, bb
        clipboard.writeText svg
        log svg
        
        for item in selected
            @selection.add item        

    paste: -> 
        
        delete @selection.pos
        @addSVG clipboard.readText()

    cut: -> 
        
        if not @selection.empty()
            @copy()
            @selection.delete()
    
    clear: -> 
        
        @selection.clear()
        @svg.clear()
        @resetView()

    #  0000000   00000000   0000000    00000000  00000000     
    # 000   000  000   000  000   000  000       000   000    
    # 000   000  0000000    000   000  0000000   0000000      
    # 000   000  000   000  000   000  000       000   000    
    #  0000000   000   000  0000000    00000000  000   000    
    
    order: (order) -> 
        
        if not @selection.empty()
            for item in @selection.items
                item[order]()    
                
    select: (select) ->
        
        switch select
            when 'none' 
                @selection.clear()
            when 'all' 
                @selection.set @items()
        
    #  0000000   0000000   000   000  00000000  
    # 000       000   000  000   000  000       
    # 0000000   000000000   000 000   0000000   
    #      000  000   000     000     000       
    # 0000000   000   000      0      00000000  
    
    save: -> 
        
        svg = @getSVG @svg.children(), x:0, y:0, width:@viewSize().x, height:@viewSize().y
        fs.writeFileSync resolve('~/Desktop/kaligraf.svg'), svg
        
    load: ->
        
        svg = fs.readFileSync resolve('~/Desktop/kaligraf.svg'), encoding: 'utf8'
        @setSVG svg
                                            
    # 000   000  000  00000000  000   000  
    # 000   000  000  000       000 0 000  
    #  000 000   000  0000000   000000000  
    #    000     000  000       000   000  
    #     0      000  00000000  00     00  
    
    onResize: (w, h) => @resetSize()
    eventPos: (event) -> pos event
    localPos: (event) -> @eventPos(event).minus @viewPos()
    stagePos: (event) -> @stageForView @localPos event
    viewPos:  -> r = @element.getBoundingClientRect(); pos r.left, r.top
    viewSize: -> r = @element.getBoundingClientRect(); pos r.width, r.height
    stageForView: (viewPos) -> pos(viewPos).scale(1.0/@zoom).plus @panPos()
    viewForStage: (stagePos) -> pos(stagePos).sub(@panPos()).scale @zoom
    
    #  0000000  00000000  000   000  000000000  00000000  00000000   
    # 000       000       0000  000     000     000       000   000  
    # 000       0000000   000 0 000     000     0000000   0000000    
    # 000       000       000  0000     000     000       000   000  
    #  0000000  00000000  000   000     000     00000000  000   000  
    
    viewCenter:  -> pos(0,0).mid @viewSize()
    stageCenter: -> boxCenter @svg.viewbox()
    stageOffset: -> boxOffset @svg.viewbox()
    itemsCenter: -> @stageForView boxCenter boxForItems @items(), @viewPos()
        
    centerAtStagePos: (stagePos) -> @moveViewBox stagePos.minus @stageCenter()
        
    # 000       0000000   000   000  00000000   00000000  
    # 000      000   000  000   000  000   000  000       
    # 000      000   000  000   000  00000000   0000000   
    # 000      000   000  000   000  000        000       
    # 0000000   0000000    0000000   000        00000000  
    
    loupe: (p1, p2) ->
        
        viewPos1 = pos(p1).sub @viewPos()
        viewPos2 = pos(p2).sub @viewPos()
        
        sc = @stageForView viewPos1.mid viewPos2
        
        sd = @stageForView(viewPos1).sub @stageForView(viewPos2)
        dw = Math.abs sd.x
        dh = Math.abs sd.y
        
        if dw == 0 or dh == 0
            z = 2
        else
            vb = @svg.viewbox()
            zw = vb.width  / dw
            zh = vb.height / dh
            z = Math.min zw, zh
            
        if @kali.tools.ctrlDown then z = 1.0/z
        
        @setZoom @zoom * z, sc

    # 000   000  000   000  00000000  00000000  000      
    # 000 0 000  000   000  000       000       000      
    # 000000000  000000000  0000000   0000000   000      
    # 000   000  000   000  000       000       000      
    # 00     00  000   000  00000000  00000000  0000000  
    
    onWheel: (event) => 
        
        oldCenter = @stageCenter()
        viewPos = @localPos event
        oldPos  = @stagePos event
        
        @setZoom @zoom * (1.0 - event.deltaY/5000.0)
        
        newPos = @viewForStage oldPos
        viewDiff = viewPos.minus newPos

        @panBy viewDiff
        
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    @zoomLevels = [
        0.01, 0.02, 0.05, 
        0.10, 0.15, 0.20, 0.25, 0.33, 0.50, 0.75,
        1, 1.5, 2, 3, 4, 5, 6, 8, 
        10, 15, 20, 40, 80, 
        100, 150, 200, 400, 800, 
        1000
    ]
    
    zoomIn: -> 
        
        for i in [0...Stage.zoomLevels.length]
            if @zoom < Stage.zoomLevels[i]
                @setZoom Stage.zoomLevels[i], @stageCenter()
                return
            
    zoomOut: -> 
        
        for i in [Stage.zoomLevels.length-1..0]
            if @zoom > Stage.zoomLevels[i]
                @setZoom Stage.zoomLevels[i], @stageCenter()
                return

    toolCenter: (zoom) ->
        
        vc = @viewCenter()
        vc.x = 560.5 if @viewSize().x > 1120
        vc.minus(pos(60.5,30.5)).scale(1/zoom)
        
    resetView: -> @setZoom 1, @toolCenter 1
    
    centerSelection: -> 
    
        items = @selection.empty() and @items() or @selection.items
        if items.length <= 0
            @centerAtStagePos @toolCenter @zoom
            return
        
        b = boxForItems items, @viewPos()
        v = @svg.viewbox()
        w = (b.w / @zoom) / v.width
        h = (b.h / @zoom) / v.height
        z = 0.8 * @zoom / Math.max(w, h)
        
        @setZoom z, @stageForView boxCenter b         
    
    setZoom: (z, sc) -> 
        
        z = clamp 0.01, 1000, z
        
        @zoom = z
        @resetSize()
        @centerAtStagePos sc if sc?
                    
    # 00000000    0000000   000   000  
    # 000   000  000   000  0000  000  
    # 00000000   000000000  000 0 000  
    # 000        000   000  000  0000  
    # 000        000   000  000   000  

    panPos: -> vb = @svg.viewbox(); pos vb.x, vb.y
    
    panBy: (delta) -> @moveViewBox pos(delta).scale -1.0/@zoom

    # 000   000  000  00000000  000   000  0000000     0000000   000   000  
    # 000   000  000  000       000 0 000  000   000  000   000   000 000   
    #  000 000   000  0000000   000000000  0000000    000   000    00000    
    #    000     000  000       000   000  000   000  000   000   000 000   
    #     0      000  00000000  00     00  0000000     0000000   000   000  
    
    resetSize: ->
        
        box = @svg.viewbox()

        box.width  = @viewSize().x / @zoom
        box.height = @viewSize().y / @zoom
        
        @svg.viewbox box
        
    moveViewBox: (delta) ->

        box = @svg.viewbox()

        box.x += delta.x
        box.y += delta.y
        
        @setViewBox box

    setViewBox: (box) ->
        
        delete box.zoom
        
        @svg.viewbox box

        box = @svg.viewbox()
        post.emit 'stage', 'viewbox', box
        post.emit 'stage', 'zoom',    @zoom
        box
        
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event, down) ->

        if down
            switch combo
                
                when 'command+-' then return @zoomOut()
                when 'command+=' then return @zoomIn()
                when 'command+0' then return @resetView()
                when 'enter', 'return', 'esc' 
                    return @shapes.endDrawing()                
        
        return if 'unhandled' != @resizer  .handleKey mod, key, combo, char, event, down
        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event, down
                
        'unhandled'
        
module.exports = Stage


#  0000000  000000000   0000000    0000000   00000000  
# 000          000     000   000  000        000       
# 0000000      000     000000000  000  0000  0000000   
#      000     000     000   000  000   000  000       
# 0000000      000     000   000   0000000   00000000  

{ resolve, elem, post, drag, last, pos, fs, log, _ } = require 'kxk'

{ growBox, normRect, boxForItems } = require './utils'

{ clipboard } = require 'electron' 

SVG       = require 'svg.js'
clr       = require 'svg.colorat.js'
Shapes    = require './shapes'
Selection = require './selection'
Resizer   = require './resizer'

class Stage

    constructor: (@kali) ->

        @element = elem 'div', id: 'stage'
        @kali.element.appendChild @element
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
        items = @selection.empty() and @svg.children() or selected
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

    #  0000000   0000000   000   000  00000000  
    # 000       000   000  000   000  000       
    # 0000000   000000000   000 000   0000000   
    #      000  000   000     000     000       
    # 0000000   000   000      0      00000000  
    
    save: -> 
        
        svg = @getSVG @svg.children(), x:0, y:0, width:@viewSize().width, height:@viewSize().height
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
    localPos: (event) -> @eventPos(event).sub @viewPos()
    stagePos: (event) -> @localPos(event).scale(1.0/@zoom).add @panPos()
    viewPos:  -> r = @element.getBoundingClientRect(); x:r.left, y:r.top
    viewSize: -> r = @element.getBoundingClientRect(); width:r.width, height:r.height
    viewCenter: -> pos(0,0).mid pos @viewSize().width, @viewSize().height 
    stageCenter: -> box = @svg.viewbox(); pos box.x + box.width/2.0, box.y + box.height/2.0
    stageForView: (viewPos) -> viewPos.scale(1.0/@zoom).add @panPos()
    
    loupe: (p1, p2) ->
        
        viewPos1 = pos(p1).sub @viewPos()
        viewPos2 = pos(p2).sub @viewPos()
        
        @centerAtStagePos @stageForView viewPos1.mid viewPos2

    centerAtStagePos: (stagePos) ->
        
        @moveViewBy stagePos.sub @stageCenter()
        
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
        log 'zoomIn', Stage.zoomLevels.length
        for i in [0...Stage.zoomLevels.length]
            log @zoom, i, Stage.zoomLevels[i]
            if @zoom < Stage.zoomLevels[i]
                @setZoom Stage.zoomLevels[i]
                return
            
    zoomOut: -> 
        log 'zoomOut'
        for i in [Stage.zoomLevels.length-1..0]
            if @zoom > Stage.zoomLevels[i]
                @setZoom Stage.zoomLevels[i]
                return
                
    resetView: -> log 'resetView'; @resetPan(); @resetZoom()
    resetZoom: -> @setZoom 1
    setZoom: (z) -> 
        log "setZoom #{z}"
        sc = @stageCenter()
        @zoom = z
        @resetSize()
        @centerAtStagePos sc
        
    resetSize: ->
        
        box = @svg.viewbox()
        # log 'resetSize', box
        box.width  = @viewSize().width  / @zoom
        box.height = @viewSize().height / @zoom
        @setViewBox box

    setViewBox: (box) ->
        
        delete box.zoom
        @svg.viewbox box
        # log 'setViewBox', box, @svg.viewbox()
        box = @svg.viewbox()
        post.emit 'stage', 'viewbox', box
        post.emit 'stage', 'zoom',    @zoom
        box
            
    # 00000000    0000000   000   000  
    # 000   000  000   000  0000  000  
    # 00000000   000000000  000 0 000  
    # 000        000   000  000  0000  
    # 000        000   000  000   000  

    panPos:    -> vb = @svg.viewbox(); pos vb.x, vb.y
    resetPan:  -> @moveViewBy @panPos().scale -1
    
    panBy: (delta) -> @moveViewBy pos(delta).scale -1.0/@zoom
    moveViewBy: (delta) ->
        log 'moveViewBy', delta
        box = @svg.viewbox()

        box.x += delta.x
        box.y += delta.y
        
        @setViewBox box
    
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event) ->

        switch combo
            
            when 'command+s'       then return @save()
            when 'command+o'       then return @load()
            when 'command+x'       then return @cut()
            when 'command+c'       then return @copy()
            when 'command+v'       then return @paste()
            when 'command+k'       then return @clear()
            when 'command+-'       then return @zoomOut()
            when 'command+='       then return @zoomIn()
            when 'command+0'       then return @resetView()
            when 'enter', 'return', 'esc' 
                return @shapes.endDrawing()                
        
        return if 'unhandled' != @resizer  .handleKey mod, key, combo, char, event
        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event
        
        'unhandled'
        
module.exports = Stage

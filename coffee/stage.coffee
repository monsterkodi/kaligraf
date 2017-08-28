
#  0000000  000000000   0000000    0000000   00000000  
# 000          000     000   000  000        000       
# 0000000      000     000000000  000  0000  0000000   
#      000     000     000   000  000   000  000       
# 0000000      000     000   000   0000000   00000000  

{ resolve, elem, post, drag, last, pos, fs, log, _ } = require 'kxk'
{ growViewBox, normRect, boxForItems } = require './utils'
{ clipboard } = require 'electron' 

SVG = require 'svg.js'
sel = require 'svg.select.js'
rsz = require 'svg.resize.js'
drw = require 'svg.draw.js'
clr = require 'svg.colorat.js'
Selection = require './selection'
Resizer   = require './resizer'

class Stage

    constructor: (@kali) ->

        @element = elem 'div', id: 'stage'
        @kali.element.appendChild @element
        @svg = SVG(@element).size '100%', '100%' 
        @svg.style
            'stroke-linecap': 'round'
            'stroke-linejoin': 'round'
        @svg.clear()
        
        @kali.stage = @
        
        @selection = new Selection @kali
        @resizer   = new Resizer   @kali
        
        @drag = new drag
            target:  @element
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop

        window.area.on 'resized', @onResize

        @resetZoom()

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
        @resetZoom()
        
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
                    if added.type != 'defs' and opt.select != false
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
        growViewBox bb
        
        svg = @getSVG items, bb
        clipboard.writeText svg
        log svg
        
        for item in selected
            @selection.add item        

    paste: -> @addSVG clipboard.readText()

    cut: -> 
        
        if not @selection.empty()
            @copy()
            @selection.delete()
    
    clear: -> 
        
        @selection.clear()
        @svg.clear()

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
                    
    #  0000000  000   000   0000000   00000000   00000000  
    # 000       000   000  000   000  000   000  000       
    # 0000000   000000000  000000000  00000000   0000000   
    #      000  000   000  000   000  000        000       
    # 0000000   000   000  000   000  000        00000000  
    
    addShape: (shape, attr, style) ->
        
        if shape == 'triangle'
            e = @svg.polygon('0,-50 100,0 0,50')
        else
            e = @svg[shape]()
            
        e.style
            stroke:           @kali.tools.stroke.color
            'stroke-opacity': @kali.tools.stroke.alpha
            'stroke-width':   @kali.tools.width.width
            
        if shape not in ['polyline', 'line']
            e.style
                fill:           @kali.tools.fill.color
                'fill-opacity': @kali.tools.fill.alpha
        else
            e.style 
                fill:           'none'
                'fill-opacity': 0.0
            
        e.attr  attr  if attr?
        e.style style if style?
        e
        
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    onDragStart: (drag, event) => @handleMouseDown event
        
    handleMouseDown: (event) ->

        @kali.focus()
        
        shape = @kali.shapeTool()
        
        for s,k of {pick:event.metaKey, pan:event.altKey, loupe:event.ctrlKey}
            if k and shape != s
                @kali.tools[s].onClick()
                shape = s
        
        ep = @eventPos(event)
                
        switch shape
            
            when 'pick'
                # e = event.target.instance
                e = @itemAtPos ep
                
                if not e?
                    log 'ADOPT!!!', event.target.id
                    e = SVG.adopt event.target
                    
                if e == @svg
                    if not event.shiftKey
                        @selection.clear()
                    @selection.start @eventPos(event), join:event.shiftKey
                else
                    if not @selection.contains e
                        if not event.shiftKey
                            @selection.clear()
                        @selection.pos = @eventPos(event)
                        @selection.add e
                    else
                        if event.shiftKey
                            @selection.del e
                            
            when 'pan'   then log 'pan'
            when 'loupe' 
                @selection.loupe = @selection.addRect 'loupe'
            else
                @selection.clear()
                @drawing = @addShape shape
                switch shape 
                    when 'triangle'
                        p = @localPos event
                        @drawing.translate p.x, p.y
                        delete @drawing
                    when 'polygon', 'polyline'
                        @drawing.draw 'point', event
                    else
                        @drawing.draw event

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onDragMove: (drag, event) =>

        switch @kali.shapeTool()
            
            when 'pan'   then @panBy drag.delta
            when 'loupe' 
                
                r = x:drag.startPos.x, y:drag.startPos.y, x2:drag.pos.x, y2:drag.pos.y                
                @selection.setRect @selection.loupe, r
                
            when 'pick'
                
                if @selection.rect?
                    @selection.move @eventPos(event), join:event.shiftKey
                # else if not @selection.empty()
                    # @selection.moveBy drag.delta
                
            when 'polygon', 'polyline'
                
                arr  = @drawing.array().valueOf()
                tail = arr.length > 1 and arr[arr.length-2] or arr[arr.length-1]
                p = @localPos event
                dist = Math.abs(tail[0]-p.x) + Math.abs(tail[1]-p.y)
                if arr.length < 2 or dist > 20
                    @drawing?.draw 'point', event
                else
                    @drawing?.draw 'update', event

    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onDragStop: (drag, event) =>
        
        if @selection.rect?
            @selection.end @eventPos event
            return
        
        switch @kali.shapeTool() 
            
            when 'loupe' 
                
                @selection.loupe.remove()
                delete @selection.loupe
                r = x:drag.startPos.x, y:drag.startPos.y, x2:drag.pos.x, y2:drag.pos.y
                normRect r
                @setViewBox x:r.x, y:r.y, width:r.x2-r.x, height:r.y2-r.y
                
            when 'polygon', 'polyline'
                
                @drawing?.draw 'done'
                
            else
                
                @drawing?.draw event
                
        @drawing = null
    
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    zoom: -> @svg.viewbox().zoom
    zoomIn:  -> @setViewBox growViewBox @svg.viewbox(), -10
    zoomOut: -> @setViewBox growViewBox @svg.viewbox()
    
    resetZoom: ->
        box = @svg.viewbox()
        box.width  = @viewSize().width
        box.height = @viewSize().height
        box.zoom = 1
        box.x = 0
        box.y = 0
        @setViewBox box
                
    # 00000000    0000000   000   000  
    # 000   000  000   000  0000  000  
    # 00000000   000000000  000 0 000  
    # 000        000   000  000  0000  
    # 000        000   000  000   000  
    
    panBy: (delta) ->
        box = @svg.viewbox()
        box.x -= delta.x / @zoom()
        box.y -= delta.y / @zoom()
        @setViewBox box
    
    # 000   000  000  00000000  000   000  
    # 000   000  000  000       000 0 000  
    #  000 000   000  0000000   000000000  
    #    000     000  000       000   000  
    #     0      000  00000000  00     00  
    
    onResize: (w, h) => @resetZoom()
    eventPos: (event) -> pos event
    localPos: (event) -> @eventPos(event).sub @viewPos()
    
    setViewBox: (box) ->
        @svg.viewbox box
        post.emit 'stage', 'viewbox', box
        post.emit 'stage', 'zoom',    box.zoom

    viewPos:  -> r = @element.getBoundingClientRect(); x:r.left, y:r.top
    viewSize: -> r = @element.getBoundingClientRect(); width:r.width, height:r.height
       
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    handleKey: (mod, key, combo, char, event) ->

        switch combo
            
            when 'command+s' then return @save()
            when 'command+o' then return @load()
            when 'command+x' then return @cut()
            when 'command+c' then return @copy()
            when 'command+v' then return @paste()
            when 'command+k' then return @clear()
            when 'command+-' then return @zoomOut()
            when 'command+=' then return @zoomIn()
            when 'command+0' then return @resetZoom()
        
        return if 'unhandled' != @selection.handleKey mod, key, combo, char, event
        
        'unhandled'
        
module.exports = Stage

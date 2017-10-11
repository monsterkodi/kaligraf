
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  000  000000000  00000000  00     00
# 000        000   000  000   000  000   000  000  000       0000  000     000     000     000     000       000   000
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     000     000     0000000   000000000
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000     000     000       000 0 000
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     000     000     00000000  000   000

{ elem, drag, clamp, post, pos, log, $, _ } = require 'kxk'

{ boundingBox, boxPos, checkersPattern, colorBrightness, id, gradientStops } = require '../utils'

Palette = require './palette'

class GradientItem

    constructor: (@kali) ->

        @element = elem class:'gradientItem'
        @element.gradient = @
        
        @svg = SVG(@element).size '100%', '100%'
        @svg.id id 'gradient'
        @svg.addClass 'gradientItemSVG'
        @svg.viewbox x:0, y:0, width:100, height:25

        @alp = @svg.rect()
        checkers = checkersPattern @svg, 2.5, '#fff'
        @alp.attr width:100, height:10, x:0, y:15, stroke: 'none', fill:checkers
        
        @grd = @svg.rect()
        @grd.width  100
        @grd.height 25
                
    del: ->
        
        @svg.clear()
        @element.remove()
        delete @svg
        delete @element
            
    setGradient: (gradient) -> 

        @gradient = @svg.gradient gradient.type, (stop) ->
            for stp in gradient.stops
                stop.at stp.offset, stp.color, stp.opacity
        @update()
    
    #  0000000  000000000   0000000   00000000    0000000  
    # 000          000     000   000  000   000  000       
    # 0000000      000     000   000  00000000   0000000   
    #      000     000     000   000  000             000  
    # 0000000      000      0000000   000        0000000   
    
    stops: -> gradientStops @gradient
    
    addStop: (offset) ->
        
        index = @indexForOffset offset
        stops = @stops()
        stops.splice index, 0, 
                offset:  offset
                color:   @kali.tool('fill').color
                opacity: @kali.tool('fill').alpha
                index:   index

        @updateGradient stops                
        
        stops[index]
        
    delStop: ->
        return if @numStops() < 2
        index = @activeIndex()
        stops = @stops()
        stops.splice index, 1
        @updateGradient stops
        @activateStop index
        
    updateGradient: (stops) ->
        
        @gradient.update (stop) ->
            for stp in stops
                stop.at stp.offset, stp.color, stp.opacity
        @createStops()
        
    stopAtPos: (eventPos) ->
        
        itemPos = @itemPosFor eventPos
        return if not (15 < itemPos.y < 25)
        minStop = null
        minDist = 666
        offset  = itemPos.x / 100
        for stop in @stops().reverse()
            dist = Math.abs offset - stop.offset
            if dist < minDist
                minStop = stop
                minDist = dist

        if (minStop.offset * 100 - 5 < itemPos.x < minStop.offset * 100 + 5)
            minStop
        else
            null

    numStops: -> @stp.children().length
    clampIndex: (index) -> clamp 0, @numStops()-1, index
            
    indexForOffset: (offset) ->
        index = 0
        for stop in @stops()
            if stop.offset < offset
                index = stop.index+1
        index
            
    itemPosFor: (eventPos) ->
        
        br = boundingBox @element
        op = eventPos.minus boxPos br
        op.mul pos 100/br.w, 25/br.h
            
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    onStopStart: (drag, event) => 
        
        eventPos = pos event
        
        itemPos = @itemPosFor eventPos
        return 'skip' if not (10 < itemPos.y < 25)
        
        if drag.stop = @stopAtPos eventPos
            @activateStop drag.stop.index
        else
            return 'skip'
        
    activateStop: (index) ->
        
        @activeStop()?.node.classList.remove 'active'
        index = @clampIndex index
        @stopAt(index)?.node.classList.add 'active'
        stop = @stops()[index]
        @kali.stopPalette?.setClosestColor stop.color, stop.opacity        
        
    activeStop: -> @stp.children().find (stop) -> stop.node.classList.contains 'active'
    activeIndex: -> @indexForStop @activeStop()
    indexForStop: (stop) -> @stp.children().indexOf stop
    stopAt: (index) -> @stp.children()[index]
        
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onStopMove:  (drag, event) => 
        
        stop = drag.stop
        eventPos = pos event
        itemPos = @itemPosFor eventPos
        prev = @prevOffset stop.index
        next = @nextOffset stop.index
        offset = clamp prev, next, itemPos.x/100
        @gradient.get(stop.index)?.update offset, stop.color, stop.opacity
        @updateStops()
    
    prevOffset: (index) ->
        if stop = @stops()[index-1]
            stop.offset
        else
            0

    nextOffset: (index) ->
        if stop = @stops()[index+1]
            stop.offset
        else
            1
            
    onStopStop:  (drag, event) => 
        
        if drag.startPos == drag.lastPos and drag.stop?
            @openPalette drag.stop

    onStopDblClick: (event) =>

        itemPos = @itemPosFor pos event
        stop = @addStop itemPos.x / 100
        @activateStop stop.index
            
    # 00000000    0000000   000      00000000  000000000  000000000  00000000  
    # 000   000  000   000  000      000          000        000     000       
    # 00000000   000000000  000      0000000      000        000     0000000   
    # 000        000   000  000      000          000        000     000       
    # 000        000   000  0000000  00000000     000        000     00000000  
    
    openPalette: (stop) ->
        
        @closePalette()
        
        br = boundingBox @element
        stopPos = boxPos br
        stopPos.add pos 0, br.h
        
        palette = new Palette @kali, 
            onLeave:@closePalette 
            onClose:@closePalette 
            halo: 
                x:      -66
                y:      0
                width:  255+2*66
                height: 2*66
        palette.proxy = 'stop'
        palette.setPos stopPos
        palette.show()
        palette.setClosestColor stop.color, stop.opacity
        
        post.on 'color', @onColor
        @kali.stopPalette = palette
        
    closePalette: =>
        
        post.removeListener 'color', @onColor
        @kali.closeStopPalette()
        
    onColor: (color, info) =>
        
        return if color != 'stop'
        
        index = @activeIndex()
        stop = @stops()[index]
        @gradient.get(index)?.update stop.offset, info.color, info.alpha
        @updateStops()
            
    #  0000000  000   000   0000000   000   000  
    # 000       000   000  000   000  000 0 000  
    # 0000000   000000000  000   000  000000000  
    #      000  000   000  000   000  000   000  
    # 0000000   000   000   0000000   00     00  
    
    showStops: ->
        
        return if @stp?
        @stp = @svg.group()
        @stp.id id 'stops'
        
        @stpDrag = new drag
            target:  @element
            onStart: @onStopStart
            onMove:  @onStopMove
            onStop:  @onStopStop
             
        @element.addEventListener 'dblclick', @onStopDblClick
            
        @createStops()
        
    hideStops: ->
        
        @element.removeEventListener 'dblclick', @onStopDblClick
        
        @stpDrag.deactivate()
        delete @stpDrag
        @stp.remove()
        delete @stp

    #  0000000  00000000   00000000   0000000   000000000  00000000  
    # 000       000   000  000       000   000     000     000       
    # 000       0000000    0000000   000000000     000     0000000   
    # 000       000   000  000       000   000     000     000       
    #  0000000  000   000  00000000  000   000     000     00000000  
    
    createStops: ->
        
        @stp.clear()
        
        for stop in @stops()
            rct = @stp.polygon '-5,5 0,0 5,5'
            rct.id id 'stop'
            rct.addClass 'gradientStop'
            rct.y 21
            
        @updateStops()
        
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
            
    updateStops: ->
                
        for stop in @stops()
            rct = @stp.children()[stop.index]
            rct.cx stop.offset * 100
            if colorBrightness(stop.color) < 0.2
                rct.style 'stroke', '#666'
            
        @update()
        post.emit 'gradient', 'changed', @state()

    update: -> @grd.fill @gradient
    
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    setActive: (active=true) ->
        
        @element.classList.toggle 'active', active
        if active then  @showStops()
        else            @hideStops()
        
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  
    
    state: -> 
        
        name: @name
        type: @gradient.type
        stops: @stops()
                
    restore: (state) ->
        
        return if not state.type? or not state.stops?
        
        @setGradient state
            
        @update()
        
module.exports = GradientItem

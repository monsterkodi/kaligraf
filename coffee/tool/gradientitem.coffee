
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  000  000000000  00000000  00     00
# 000        000   000  000   000  000   000  000  000       0000  000     000     000     000     000       000   000
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     000     000     0000000   000000000
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000     000     000       000 0 000
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     000     000     00000000  000   000

{ elem, drag, clamp, pos, log, $, _ } = require 'kxk'

{ boundingBox, boxPos, checkersPattern, id } = require '../utils'

class GradientItem

    constructor: (@list) ->

        @kali = @list.kali
        
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
        
        @setGradient 
            type: 'linear'
            stops: [
                offset:  0.0
                color:   @kali.tool('stroke').color
                opacity: @kali.tool('stroke').alpha
            ,
                offset:  1.0
                color:   @kali.tool('fill').color
                opacity: @kali.tool('fill').alpha
            ]
        
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
    
    stops: ->
        i = 0
        stops = []
        while stop = @gradient.get i
            stops.push
                offset:  stop.attr 'offset'
                color:   stop.attr 'stop-color'
                opacity: stop.attr 'stop-opacity'
                index:   i
            i++
        stops

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
        index = @activeIndex()
        stops = @stops()
        stops.splice index, 1
        @updateGradient stops
        @stopAt(@clampIndex index)?.node.classList.add 'active'
        
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
        for stop in @stops()
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
        
        if stop = @stopAtPos eventPos
            drag.stop = stop
        else
            drag.stop = @addStop itemPos.x / 100
        
        @activeStop()?.node.classList.remove 'active'
        @stopAt(drag.stop.index)?.node.classList.add 'active'
        
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
        
        if drag.startPos == drag.lastPos
            log 'onStopStop', event.target.tagName
            
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
             
        @createStops()
                        
    hideStops: ->
        
        @stpDrag.deactivate()
        delete @stpDrag
        @stp.remove()
        delete @stp

    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
            
    updateStops: ->
        
        for stop in @stops()
            rct = @stp.children()[stop.index]
            rct.cx stop.offset * 100
            
        @update()

    update: -> @grd.fill @gradient

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
            rct.y 20
            
        @updateStops()
    
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
        
        type: @gradient.type
        stops: @stops()
                
    restore: (state) ->
        
        return if not state.type? or not state.stops?
        
        @setGradient state
            
        @update()
        
module.exports = GradientItem

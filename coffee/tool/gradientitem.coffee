
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  000  000000000  00000000  00     00
# 000        000   000  000   000  000   000  000  000       0000  000     000     000     000     000       000   000
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     000     000     0000000   000000000
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000     000     000       000 0 000
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     000     000     00000000  000   000

{ elem, drag, clamp, pos, log, $, _ } = require 'kxk'

{ boundingBox, boxPos, id } = require '../utils'

class GradientItem

    constructor: (@list) ->

        @kali = @list.kali
        
        @element = elem class:'gradientItem'
        @element.gradient = @
        
        @svg = SVG(@element).size '100%', '100%'
        @svg.id id 'gradient'
        @svg.addClass 'gradientItemSVG'
        @svg.viewbox x:0, y:0, width:100, height:25
                
        @grd = @svg.rect()
        @grd.width  100
        @grd.height 25
        
        @setGradient @svg.gradient 'linear', (stop) =>
            stop.at 0.0, @kali.tool('stroke').color
            stop.at 1.0, @kali.tool('fill').color
        
    setGradient: (@gradient) -> @update()
    
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
        
        @gradient.at offset, @kali.tool('fill').color
        @createStops()
        
    stopAtPos: (eventPos) ->
        
        itemPos = @itemPosFor eventPos
        return if not (20 < itemPos.y < 25)
        for stop in @stops()
            return stop if (stop.offset * 100 - 5 < itemPos.x < stop.offset * 100 + 5)

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
        return 'skip' if not (20 < itemPos.y < 25)
        
        if stop = @stopAtPos eventPos
            log 'onStopStart', stop
            drag.stop = stop
        else
            @addStop itemPos.x / 100
            return 'skip'
        
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    onStopMove:  (drag, event) => 
        stop = drag.stop
        eventPos = pos event
        itemPos = @itemPosFor eventPos
        offset = clamp 0, 1, itemPos.x/100
        log 'onStopMove', stop, offset
        @gradient.get(stop.index).update offset, stop.color, stop.opacity
        @updateStops()
    
    onStopStop:  (drag, event) => 
        
        log 'onStopStop',  event.target.tagName
            
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
    
    createStops: ->
        
        @stp.clear()
        
        for stop in @stops()
            rct = @stp.polygon '-5,5 0,0 5,5'
            rct.id id 'stop'
            rct.addClass 'gradientStop'
            rct.y 20
            
        @updateStops()
        
    updateStops: ->
        
        for stop in @stops()
            rct = @stp.children()[stop.index]
            rct.cx stop.offset * 100
            
        @update()

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
        
        type: @gradient.type
        stops: @stops()
                
    restore: (state) ->
        
        return if not state.type? or not state.stops?
        
        @gradient = @svg.gradient state.type
        for stop in state.stops
            continue if not stop.offset? or not stop.color? or not stop.opacity?
            @gradient.at stop.offset, stop.color, stop.opacity
            
        @update()
        
module.exports = GradientItem

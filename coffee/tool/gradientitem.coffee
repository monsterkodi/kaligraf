
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  000  000000000  00000000  00     00
# 000        000   000  000   000  000   000  000  000       0000  000     000     000     000     000       000   000
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     000     000     0000000   000000000
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000     000     000       000 0 000
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     000     000     00000000  000   000

{ elem, log, $, _ } = require 'kxk'

class GradientItem

    constructor: (@list) ->

        @kali = @list.kali
        
        @element = elem class:'gradientItem'
        @element.gradient = @
        
        @svg = SVG(@element).size '100%', '100%'
        @svg.addClass 'gradientItemSVG'
        @svg.viewbox x:0, y:0, width:100, height:25
                
        @grd = @svg.rect()
        @grd.width  100
        @grd.height 25
        
        @setGradient @svg.gradient 'linear', (stop) =>
            stop.at 0.0, @kali.tool('stroke').color
            stop.at 1.0, @kali.tool('fill').color
        
    update: -> @grd.fill @gradient
        
    setGradient: (@gradient) -> @update()
    
    state: -> 
        type: @gradient.type
        stops: @stops()
        
    stops: ->
        i = 0
        stops = []
        while stop = @gradient.get i            
            stops.push 
                offset:  stop.attr 'offset'
                color:   stop.attr 'stop-color'
                opacity: stop.attr 'stop-opacity'
            i++
        stops
        
    restore: (state) ->
        # log "GradientItem.restore", state
        return if not state.type? or not state.stops?
        @gradient = @svg.gradient state.type
        for stop in state.stops
            continue if not stop.offset? or not stop.color? or not stop.opacity?
            @gradient.at stop.offset, stop.color, stop.opacity
            
        @update()
        
module.exports = GradientItem

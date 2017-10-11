
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  00000000  0000000    000  000000000
# 000        000   000  000   000  000   000  000  000       0000  000     000     000       000   000  000     000   
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     0000000   000   000  000     000   
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000       000   000  000     000   
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     00000000  0000000    000     000   

{ gradientState } = require '../utils'

Tool         = require './tool'
GradientItem = require './gradientitem'

WIDTH  = 255

class GradientEdit extends Tool

    constructor: (@kali, cfg) ->

        cfg       ?= {}
        cfg.name  ?= 'GradientEdit'
        cfg.class ?= 'GradientEdit'
        
        cfg.halo        ?= {}
        cfg.halo.x      ?= 0
        cfg.halo.width  ?= 255+66
        
        super @kali, cfg

        @gradientItem = new GradientItem @kali
        @gradientItem.name = cfg.name
        @element.style.width = "#{WIDTH}px"
        
        @element.appendChild @gradientItem.element

    del: ->
        
        @element.remove()
        delete @element
        
    setGradient: (gradient) ->
        
        state = gradientState gradient
        state.type = 'linear'
        @gradientItem.setGradient state
        @gradientItem.setActive()

    # 00000000  000   000  00000000  000   000  000000000   0000000
    # 000       000   000  000       0000  000     000     000
    # 0000000    000 000   0000000   000 0 000     000     0000000
    # 000          000     000       000  0000     000          000
    # 00000000      0      00000000  000   000     000     0000000

    onMouseEnter: => @addHalo()
    
    onMouseLeave: => 
        @delHalo()
        @cfg.onLeave?()
        
module.exports = GradientEdit

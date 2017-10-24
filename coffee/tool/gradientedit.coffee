
#  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  00000000  0000000    000  000000000
# 000        000   000  000   000  000   000  000  000       0000  000     000     000       000   000  000     000   
# 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     0000000   000   000  000     000   
# 000   000  000   000  000   000  000   000  000  000       000  0000     000     000       000   000  000     000   
#  0000000   000   000  000   000  0000000    000  00000000  000   000     000     00000000  0000000    000     000   

{ log } = require 'kxk'
{ gradientState } = require '../utils'

Tool         = require './tool'
GradientItem = require './gradientitem'

class GradientEdit extends Tool

    constructor: (@kali, cfg) ->

        cfg       ?= {}
        cfg.name  ?= 'GradientEdit'
        cfg.class ?= 'GradientEdit'
        
        @width = cfg.width ? 360
        
        cfg.halo        ?= {}
        cfg.halo.x      ?= 0
        cfg.halo.width  ?= @width+@kali.toolSize
        
        super @kali, cfg

        @gradientItem = new GradientItem @kali
        @gradientItem.name = cfg.name
        @element.style.width = "#{@width}px"
        @element.style.overflow = 'visible'
        
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

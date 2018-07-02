###
 0000000  00000000  000      00000000   0000000  000000000  
000       000       000      000       000          000     
0000000   0000000   000      0000000   000          000     
     000  000       000      000       000          000     
0000000   00000000  0000000  00000000   0000000     000     
###

{ prefs, log, _ } = require 'kxk'

Tool = require './tool'

class Select extends Tool

    constructor: (kali, cfg) ->
        
        super kali, cfg
                
        @initTitle()

        @fillStroke = prefs.get 'select:fillStroke', 'fill-stroke'
        @shapeText  = prefs.get 'select:shapeText',  'shape-text'
        
        @initButtons [
            name: 'fill'
            tiny: 'select-fill'
            choice: @fillStroke
            action: => @setFillStroke 'fill'
        ,
            name: 'fill-stroke'
            tiny: 'select-fill-stroke'
            choice: @fillStroke
            action: => @setFillStroke 'fill-stroke'
        ,
            name: 'stroke'
            tiny: 'select-stroke'
            choice: @fillStroke
            action: => @setFillStroke 'stroke'
        ]
        
        @initButtons [
            name:   'shape'
            tiny:   'select-shape'
            choice: @shapeText
            action: => @setShapeText 'shape'
        ,
            name:   'shape-text'
            tiny:   'select-shape-text'
            choice: @shapeText
            action: => @setShapeText 'shape-text'
        ,
            name:   'text'
            tiny:   'select-text'
            choice: @shapeText
            action: => @setShapeText 'text'
        ]
        
    setFillStroke: (@fillStroke) ->

        prefs.set 'select:fillStroke', @fillStroke
        
    setShapeText: (@shapeText) ->
        
        prefs.set 'select:shapeText', @shapeText
        
    shapeTextOpt: ->
        
        opt = {}
        opt.noType = 'text' if not @shapeText.includes 'text' 
        opt.type   = 'text' if not @shapeText.includes 'shape'
        opt
        
module.exports = Select

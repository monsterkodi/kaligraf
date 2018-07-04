###
 0000000  000   000   0000000   00000000   000000000   0000000   00000000    0000000   00000000  000000000
000       0000  000  000   000  000   000     000     000   000  000   000  000        000          000   
0000000   000 0 000  000000000  00000000      000     000000000  0000000    000  0000  0000000      000   
     000  000  0000  000   000  000           000     000   000  000   000  000   000  000          000   
0000000   000   000  000   000  000           000     000   000  000   000   0000000   00000000     000   
###

{ log, _ } = require 'kxk'

class SnapTarget

    constructor: (@kali, @box, @closest) ->
        
        @circle = @box.doc().circle 20 / @kali.stage.zoom
        @circle.cx @closest.pos.x
        @circle.cy @closest.pos.y
        @circle.style
            stroke:           '#000'
            'stroke-opacity': 0.5
            fill:             '#fff'
            'fill-opacity':   0.5
        
    del: ->
        
        @circle.remove()
        
module.exports = SnapTarget

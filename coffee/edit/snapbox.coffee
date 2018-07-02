###
 0000000  000   000   0000000   00000000   0000000     0000000   000   000
000       0000  000  000   000  000   000  000   000  000   000   000 000 
0000000   000 0 000  000000000  00000000   0000000    000   000    00000  
     000  000  0000  000   000  000        000   000  000   000   000 000 
0000000   000   000  000   000  000        0000000     0000000   000   000
###

{ log, _ } = require 'kxk'

class SnapBox

    constructor: () ->

    @svgElemAtPos: (tools, root, stagePos) ->
                
        e = root.rect 0, 0 
        e.radius tools.radius.radius
        e
                
module.exports = SnapBox

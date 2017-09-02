
# 000000000  00000000    0000000   000   000   0000000
#    000     000   000  000   000  0000  000  000     
#    000     0000000    000000000  000 0 000  0000000 
#    000     000   000  000   000  000  0000       000
#    000     000   000  000   000  000   000  0000000 

{ pos, log, _ } = require 'kxk'

class Trans

    constructor: (@kali) ->

    center:    (item, c) -> if c? then @setCenter(item, c) else @getCenter item
    setCenter: (item, c) -> item.transform x:c.x, y:c.y; c
    getCenter: (item) -> pos item.transform('x'), item.transform('y')

    size: (item) -> pos item.width(), item.height()
    
module.exports = Trans

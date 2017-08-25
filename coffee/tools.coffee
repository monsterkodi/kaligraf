
# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 


{ elem, stopEvent, log
}    = require 'kxk'
Tool = require './tool'

WIDTH  = 30
HEIGHT = 300

class Tools extends Tool

    constructor: (parent) ->
                
        super name: 'tools', parent: parent
        
    onClick: (e) =>
        log 'tools'
        
module.exports = Tools

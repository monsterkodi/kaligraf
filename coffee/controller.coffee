
#  0000000   0000000   000   000  000000000  00000000    0000000   000      000      00000000  00000000 
# 000       000   000  0000  000     000     000   000  000   000  000      000      000       000   000
# 000       000   000  000 0 000     000     0000000    000   000  000      000      0000000   0000000  
# 000       000   000  000  0000     000     000   000  000   000  000      000      000       000   000
#  0000000   0000000   000   000     000     000   000   0000000   0000000  0000000  00000000  000   000

{log, setStyle} = require 'kxk'
Menu  = require './menu'
Stage = require './stage'

class Controller

    constructor: (cfg) ->
        
        @element = cfg?.element ? window
        @stage   = new Stage @element
        
    setMenu: (menu) ->
        
        @menu?.remove()
        @menu = new Menu @, menu
                    
    setStyle: (name) ->
        
        link = document.createElement 'link'
        link.rel='stylesheet' 
        link.href="#{__dirname}/css/#{name}.css"  
        link.type='text/css'
        document.head.appendChild link
        
module.exports = Controller

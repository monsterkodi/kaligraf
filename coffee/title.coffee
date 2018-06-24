###
000000000  000  000000000  000      00000000
   000     000     000     000      000     
   000     000     000     000      0000000 
   000     000     000     000      000     
   000     000     000     0000000  00000000
###

{ log, $ } = require 'kxk'

Tabs = require './tabs'

class Title
    
    constructor: () ->

        @elem =$ "#titlebar"
        @tabs = new Tabs @elem

    swapForTabs: (swapIn) -> 
        @tabs.div.parentNode.insertBefore swapIn, @tabs.div
        @tabs.div.style.display = 'none'
        
    restoreTabs: ->
        @tabs.div.previousSibling.remove()
        @tabs.div.style.display = ''
            
module.exports = Title

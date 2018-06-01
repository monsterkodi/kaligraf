###
000000000  000  000000000  000      00000000
   000     000     000     000      000     
   000     000     000     000      0000000 
   000     000     000     000      000     
   000     000     000     0000000  00000000
###

{ elem, slash, post, str, log, $ } = require 'kxk'

pkg  = require '../package.json'
Tabs = require './tabs'

class Title
    
    constructor: () ->

        { title } = require 'kxk'
        window.titlebar = new title
            pkg:    pkg 
            menu:   __dirname + '/../coffee/menu.noon' 
            icon:   __dirname + '/../img/menu@2x.png'
        
        @elem =$ "#titlebar"

        @tabs = new Tabs @elem

    swapForTabs: (swapIn) -> 
        @tabs.div.parentNode.insertBefore swapIn, @tabs.div
        @tabs.div.style.display = 'none'
        
    restoreTabs: ->
        @tabs.div.previousSibling.remove()
        @tabs.div.style.display = ''
            
module.exports = Title


# 000   000   0000000   000      000  
# 000  000   000   000  000      000  
# 0000000    000000000  000      000  
# 000  000   000   000  000      000  
# 000   000  000   000  0000000  000  

{ setStyle, keyinfo, log } = require 'kxk'
Menu   = require './menu'
Stage  = require './stage'
Tools  = require './tools'

class Kali

    constructor: (cfg) ->
        
        @element = cfg?.element ? window
        @stage  = new Stage @
        @tools  = new Tools @, name: 'tools', text: 'tools'
        
        @focus()
        document.addEventListener 'keydown', @onKeyDown

    focus: -> @element.focus()
        
    onKeyDown: (event) =>
    
        {mod, key, combo, char} = keyinfo.forEvent event
        log "Kali.onKeyDown mod:#{mod} key:#{key} combo:#{combo} char:#{char}"
        
        return if 'unhandled' != @stage.handleKey mod, key, combo, char, event
        
    shapeTool: -> @tools.getActive('shape').name    
    
    setMenu: (menu) ->
        
        @menu?.remove()
        @menu = new Menu @, menu
                    
    setStyle: (name) ->
        
        link = document.createElement 'link'
        link.rel='stylesheet' 
        link.href="#{__dirname}/css/#{name}.css"  
        link.type='text/css'
        document.head.appendChild link
        
module.exports = Kali
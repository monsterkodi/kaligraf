
# 000   000   0000000   000      000  
# 000  000   000   000  000      000  
# 0000000    000000000  000      000  
# 000  000   000   000  000      000  
# 000   000  000   000  0000000  000  

{ setStyle, keyinfo, stopEvent, elem, log, $ } = require 'kxk'

Stage = require './stage'
Tools = require './tools'
Menu  = require './menu'
Trans = require './trans'

class Kali

    constructor: (cfg) ->
        
        @element = cfg?.element ? window
        @toolDiv = elem 'div', id: 'tools'
        @element.appendChild @toolDiv
                
        @menus   = new Menu  @
        @trans   = new Trans @
        @tools   = new Tools @, name: 'tools', text: 'tools', orient: 'down'
        @stage   = new Stage @
        
        @focus()
        @element.addEventListener 'keydown', @onKeyDown
        @element.addEventListener 'keyup',   @onKeyUp
        
        @tools.init()
        @tools.loadPrefs()

    focus: -> @element.focus()
        
    onKeyDown: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        return stopEvent(event) if 'unhandled' != @tools.handleKey mod, key, combo, char, event, true
        return stopEvent(event) if 'unhandled' != @menus.handleKey mod, key, combo, char, event, true
        return stopEvent(event) if 'unhandled' != @stage.handleKey mod, key, combo, char, event, true

    onKeyUp: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        return stopEvent(event) if 'unhandled' != @tools.handleKey mod, key, combo, char, event, false
        return stopEvent(event) if 'unhandled' != @menus.handleKey mod, key, combo, char, event, false
        return stopEvent(event) if 'unhandled' != @stage.handleKey mod, key, combo, char, event, false
        
    shapeTool: -> @tools.getActive('shape').name
    
    items: -> @stage.items()
            
    setStyle: (name) ->
        
        if not $('kali-style')
            link = document.createElement 'link'
            link.rel  ='stylesheet'
            link.id   = 'kali-style'
            link.href ="#{__dirname}/css/#{name}.css"  
            link.type ='text/css'
            document.head.appendChild link
        
module.exports = Kali

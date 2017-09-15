
# 000   000   0000000   000      000  
# 000  000   000   000  000      000  
# 0000000    000000000  000      000  
# 000  000   000   000  000      000  
# 000   000  000   000  0000000  000  

{ setStyle, keyinfo, stopEvent, empty, post, prefs, elem, log, $ } = require 'kxk'

Stage   = require './stage'
Tools   = require './tools'
Menu    = require './menu'
Trans   = require './trans'
Browser = require './browser'

class Kali

    constructor: (cfg) ->
        
        prefs.init()
        
        @app = cfg.app
        @element = cfg?.element ? window
        @element.style.overflow = 'initial'
        @element.parentNode.style.overflow = 'initial'
        @toolDiv = elem 'div', id: 'tools'
        @element.appendChild @toolDiv
        
        @toolSize = 66
        
        @menus   = new Menu  @
        @trans   = new Trans @
        @tools   = new Tools @, name: 'tools', text: 'tools', orient: 'down'
        @stage   = new Stage @
        
        @focus()
        @element.addEventListener 'keydown', @onKeyDown
        @element.addEventListener 'keyup',   @onKeyUp
        
        @tools.init()
        @tools.loadPrefs()

    # 00000000   00000000   0000000  00000000  000   000  000000000  
    # 000   000  000       000       000       0000  000     000     
    # 0000000    0000000   000       0000000   000 0 000     000     
    # 000   000  000       000       000       000  0000     000     
    # 000   000  00000000   0000000  00000000  000   000     000     
    
    openRecent: ->
        
        recent = prefs.get 'recent', []
        if empty recent
            post.emit 'tool', 'open'
        else
            @browser = new Browser @, recent
        
    items: -> @stage.items()
    
    insertBelowTools: (child) -> @element.insertBefore child, @toolDiv
    insertAboveTools: (child) -> 
        @element.appendChild child
        child.style.zIndex = 1000

    shapeTool:    -> @tools.getActive('shape')?.name
        
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
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
                
    #  0000000  000000000  000   000  000      00000000  
    # 000          000      000 000   000      000       
    # 0000000      000       00000    000      0000000   
    #      000     000        000     000      000       
    # 0000000      000        000     0000000  00000000  
    
    setStyle: (name) ->
        
        if not $('kali-style')
            link = document.createElement 'link'
            link.rel  ='stylesheet'
            link.id   = 'kali-style'
            link.href ="#{__dirname}/css/#{name}.css"  
            link.type ='text/css'
            document.head.appendChild link
        
module.exports = Kali

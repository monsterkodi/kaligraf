
# 000   000   0000000   000      000  
# 000  000   000   000  000      000  
# 0000000    000000000  000      000  
# 000  000   000   000  000      000  
# 000   000  000   000  0000000  000  

{ setStyle, keyinfo, stopEvent, empty, first, post, prefs, elem, log, $, _ } = require 'kxk'

Stage   = require './stage'
Tools   = require './tools'
Trans   = require './trans'
Browser = require './browser'

class Kali

    constructor: (element) ->
        
        prefs.init()
        @setStyle 'style'
        
        @element =$ element 
        @element.style.overflow = 'initial'
        @element.parentNode.style.overflow = 'initial'
        @toolDiv = elem 'div', id: 'tools'
        @element.appendChild @toolDiv
        
        @toolSize = 66
        
        @trans   = new Trans @
        @tools   = new Tools @, name: 'tools', text: 'tools', orient: 'down'
        @stage   = new Stage @
        
        @focus()
        @element.addEventListener 'keydown', @onKeyDown
        @element.addEventListener 'keyup',   @onKeyUp
        
        @tools.init()
        @tools.loadPrefs()

        post.setMaxListeners 100
        # post.on 'slog', (t) -> window.logview?.appendText t
        
        window.onresize = @kali.stage.resetSize
                
    # 00000000   00000000   0000000  00000000  000   000  000000000  
    # 000   000  000       000       000       0000  000     000     
    # 0000000    0000000   000       0000000   000 0 000     000     
    # 000   000  000       000       000       000  0000     000     
    # 000   000  00000000   0000000  00000000  000   000     000     
    
    openRecent: ->
        
        recent = _.clone prefs.get 'recent', []
        if empty recent
            post.emit 'tool', 'open'
        else
            if first(recent) == @stage.currentFile
                recent.shift()
            @browser ?= new Browser @, recent
            
    closeBrowser: ->
        
        @browser?.del()
        delete @browser
        
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
        return stopEvent(event) if 'unhandled' != @stage.handleKey mod, key, combo, char, event, true

    onKeyUp: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        return stopEvent(event) if 'unhandled' != @tools.handleKey mod, key, combo, char, event, false
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

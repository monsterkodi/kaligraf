
# 000   000   0000000   000      000  
# 000  000   000   000  000      000  
# 0000000    000000000  000      000  
# 000  000   000   000  000      000  
# 000   000  000   000  0000000  000  

{ setStyle, keyinfo, stopEvent, empty, first, post, prefs, elem, sw, sh, pos, log, $, _ } = require 'kxk'

Tools    = require './tool/tools'
Cursor   = require './cursor'
Stage    = require './stage'
Trans    = require './trans'
Browser  = require './browser'
FileInfo = require './fileinfo'

class Kali

    constructor: (element) ->

        # post.debug ['emit']
        post.setMaxListeners 30
        
        @setStyle 'style'
        
        prefs.init()
        
        Cursor.kali = @
        
        @element =$ element 
        @toolDiv = elem id: 'tools'
        @element.appendChild @toolDiv
        
        @toolSize     = 75
        @paletteWidth = 375
        
        @trans = new Trans @
        @tools = new Tools @, name: 'tools', text: 'tools', orient: 'down'
        @stage = new Stage @
        
        @tools.init()
        
        @fileInfo = new FileInfo @
        
        @focus()
        @element.addEventListener 'keydown', @onKeyDown
        @element.addEventListener 'keyup',   @onKeyUp
                
        window.onresize = @onResize
        
        @tools.loadPrefs()
        
    onResize: => 

        post.emit 'resize', pos sw(), sh()
                
    # 0000000    00000000    0000000   000   000   0000000  00000000  00000000   
    # 000   000  000   000  000   000  000 0 000  000       000       000   000  
    # 0000000    0000000    000   000  000000000  0000000   0000000   0000000    
    # 000   000  000   000  000   000  000   000       000  000       000   000  
    # 0000000    000   000   0000000   00     00  0000000   00000000  000   000  
    
    openBrowser: ->
        
        recent = _.clone prefs.get 'recent', []
        if empty recent
            post.emit 'tool', 'open'
        else if @browser?
            @browser.openFile @browser.selectedFile()
        else
            @browser = new Browser @
            @browser.browseRecent recent
            
    closeBrowser: ->
        
        @browser?.del()
        delete @browser

    closeStopPalette: ->
        
        if palette = @stopPalette
            delete @stopPalette
            palette.del()
        
    insertAboveSelection: (child) -> @element.insertBefore child, @stage.selection.element.nextSibling
    insertAboveStage: (child) -> @element.insertBefore child, @stage.element.nextSibling
    insertBelowTools: (child) -> @element.insertBefore child, @toolDiv
    insertAboveTools: (child) -> 
        @element.appendChild child
        child.style.zIndex = 1000
        
    shapeTool: -> @tools.getActive('shape')?.name
    tool: (name) -> @tools.getTool name 
        
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
            log 'setStyle'
            link = document.createElement 'link'
            link.rel  ='stylesheet'
            link.id   = 'kali-style'
            link.href ="#{__dirname}/css/#{name}.css"  
            link.type ='text/css'
            document.head.appendChild link
        
module.exports = Kali

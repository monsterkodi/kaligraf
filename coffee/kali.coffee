###
000   000   0000000   000      000  
000  000   000   000  000      000  
0000000    000000000  000      000  
000  000   000   000  000      000  
000   000  000   000  0000000  000  
###

{ keyinfo, stopEvent, empty, first, post, prefs, popup, elem, sw, sh, pos, log, $, _ } = require 'kxk'

Tools    = require './tool/tools'
Cursor   = require './cursor'
Stage    = require './stage'
Trans    = require './trans'
Browser  = require './browser'
FileInfo = require './fileinfo'
Title    = require './title'
Menu     = require './menu'

electron = require 'electron'

remote   = electron.remote
win      = window.win = remote.getCurrentWindow()

class Kali

    constructor: (element) ->

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

        window.title = new Title
        window.menu  = new Menu
        
        post.on 'menuAction', @onMenuAction
        
        @initContextMenu()
        
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
    
    # 00     00  00000000  000   000  000   000      0000000    0000000  000000000  000   0000000   000   000
    # 000   000  000       0000  000  000   000     000   000  000          000     000  000   000  0000  000
    # 000000000  0000000   000 0 000  000   000     000000000  000          000     000  000   000  000 0 000
    # 000 0 000  000       000  0000  000   000     000   000  000          000     000  000   000  000  0000
    # 000   000  00000000  000   000   0000000      000   000   0000000     000     000   0000000   000   000
    
    onMenuAction: (name, args) =>
    
        log name, args
        switch name
    
            when 'Toggle Menu'      then return window.menu.toggle()
            when 'Show Menu'        then return window.menu.show()
            when 'Hide Menu'        then return window.menu.hide()
            when 'DevTools'         then return win.webContents.toggleDevTools()
            when 'Reload'           then return win.webContents.reloadIgnoringCache()
            when 'Close Window'     then return win.close()
            when 'Minimize'         then return win.minimize()
            when 'Maximize'         then return if win.isMaximized() then win.unmaximize() else win.maximize()  
            
        log "unhandled menu action! ------------ posting to main '#{name}' args: #{args}"
        
        post.toMain 'menuAction', name, args

    #  0000000   0000000   000   000  000000000  00000000  000   000  000000000  
    # 000       000   000  0000  000     000     000        000 000      000     
    # 000       000   000  000 0 000     000     0000000     00000       000     
    # 000       000   000  000  0000     000     000        000 000      000     
    #  0000000   0000000   000   000     000     00000000  000   000     000     

    initContextMenu: ->
        
        $("#kali").addEventListener "contextmenu", (event) ->
            
            absPos = pos event
            if not absPos?
                absPos = pos $("#kali").getBoundingClientRect().left, $("#kali").getBoundingClientRect().top
                
            opt = items: [
                text:   'Clear'
                combo:  'ctrl+k'
                cb:     -> post.emit 'menuAction', 'Clear'
            ,
                text:   'Toggle Menu'
                combo:  'alt+m'
                cb:     -> post.emit 'menuAction', 'Toggle Menu'
            ]
            
            opt.x = absPos.x
            opt.y = absPos.y
        
            popup.menu opt
                
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
            # log 'setStyle'
            link = document.createElement 'link'
            link.rel  ='stylesheet'
            link.id   = 'kali-style'
            link.href ="#{__dirname}/css/#{name}.css"  
            link.type ='text/css'
            document.head.appendChild link
        
module.exports = Kali


#  0000000   00000000   00000000   
# 000   000  000   000  000   000  
# 000000000  00000000   00000000   
# 000   000  000        000        
# 000   000  000        000        

{ about, prefs, post, noon, fs, log } = require 'kxk'

pkg      = require '../package.json'
MainMenu = require './mainmenu'
electron = require 'electron'
colors   = require 'colors'

app      = electron.app
Browser  = electron.BrowserWindow
Menu     = electron.Menu
ipc      = electron.ipcMain

kaliapp  = undefined # < created in app.on 'ready'

#  0000000   00000000    0000000    0000000
# 000   000  000   000  000        000     
# 000000000  0000000    000  0000  0000000 
# 000   000  000   000  000   000       000
# 000   000  000   000   0000000   0000000 

args  = require('karg') """

#{pkg.productName}

    noprefs   . ? don't load preferences  . = false
    verbose   . ? log more                . = false
    DevTools  . ? open developer tools    . = false
    debug     .                             = false
     
version  #{pkg.version}

""", dontExit: true

app.exit 0 if not args?

if args.verbose
    log colors.white.bold "\n#{pkg.productName}", colors.gray "v#{pkg.version}\n"
    log colors.yellow.bold 'process'
    p = cwd: process.cwd()
    log noon.stringify p, colors:true
    log colors.yellow.bold 'args'
    log noon.stringify args, colors:true
    log ''

# 000   000  000  000   000   0000000
# 000 0 000  000  0000  000  000     
# 000000000  000  000 0 000  0000000 
# 000   000  000  000  0000       000
# 00     00  000  000   000  0000000 

wins        = -> Browser.getAllWindows()
activeWin   = -> Browser.getFocusedWindow()
visibleWins = -> (w for w in wins() when w?.isVisible() and not w?.isMinimized())
winWithID   = (winID) -> Browser.fromId winID

# 000  00000000    0000000
# 000  000   000  000     
# 000  00000000   000     
# 000  000        000     
# 000  000         0000000

ipc.on 'toggleDevTools', (event)        => event.sender.toggleDevTools()
ipc.on 'maximizeWindow', (event, winID) => kaliapp.toggleMaximize winWithID winID
ipc.on 'activateWindow', (event, winID) => kaliapp.activateWindowWithID winID
ipc.on 'reloadWindow',   (event, winID) => kaliapp.reloadWin winWithID winID
                        
# 000   000   0000000   000      000   0000000   00000000   00000000     
# 000  000   000   000  000      000  000   000  000   000  000   000    
# 0000000    000000000  000      000  000000000  00000000   00000000     
# 000  000   000   000  000      000  000   000  000        000          
# 000   000  000   000  0000000  000  000   000  000        000          

class KaliApp
    
    constructor: () -> 
        
        prefs.init()
        
        if app.makeSingleInstance @otherInstanceStarted
            app.exit 0
            return

        app.setName pkg.productName
                                
        @createWindow()

        MainMenu.init @

    # 000   000  000  000   000  0000000     0000000   000   000   0000000
    # 000 0 000  000  0000  000  000   000  000   000  000 0 000  000     
    # 000000000  000  000 0 000  000   000  000   000  000000000  0000000 
    # 000   000  000  000  0000  000   000  000   000  000   000       000
    # 00     00  000  000   000  0000000     0000000   00     00  0000000 

    reloadWin: (win) -> win?.webContents.reloadIgnoringCache()

    toggleMaximize: (win) ->
        if win.isMaximized()
            win.unmaximize() 
        else
            win.maximize()        

    toggleWindows: =>
        if wins().length
            if visibleWins().length
                if activeWin()
                    @hideWindows()
                else
                    @raiseWindows()
            else
                @showWindows()
        else
            args.show = true
            @createWindow()

    hideWindows: =>
        for w in wins()
            w.hide()
            
    showWindows: =>
        for w in wins()
            w.show()
            
    raiseWindows: =>
        if visibleWins().length
            for w in visibleWins()
                w.showInactive()
            visibleWins()[0].showInactive()
            visibleWins()[0].focus()
    
    closeWindows: =>
        w.close() for w in wins()
    
    screenSize: -> electron.screen.getPrimaryDisplay().workAreaSize
                    
    #  0000000  00000000   00000000   0000000   000000000  00000000
    # 000       000   000  000       000   000     000     000     
    # 000       0000000    0000000   000000000     000     0000000 
    # 000       000   000  000       000   000     000     000     
    #  0000000  000   000  00000000  000   000     000     00000000
       
    createWindow: () ->
        
        bounds = prefs.get 'bounds', null
        if not bounds
            {w, h} = @screenSize()
            bounds = {}
            bounds.width = h + 122
            bounds.height = h
            bounds.x = parseInt (w-bounds.width)/2
            bounds.y = 0
            
        win = new Browser
            x:               bounds.x
            y:               bounds.y
            width:           bounds.width
            height:          bounds.height
            minWidth:        556
            minHeight:       206
            useContentSize:  true
            fullscreenable:  true
            show:            false
            backgroundColor: '#000'
            titleBarStyle:   'hidden'

        win.loadURL "file://#{__dirname}/index.html"
        
        win.on 'close',  @onCloseWin
        win.on 'move',   @onMoveWin
        win.on 'resize', @onResizeWin
                               
        winReadyToShow = =>
            win.show()
            win.focus()
             
            if args.DevTools then win.webContents.openDevTools()
                        
        win.on 'ready-to-show', winReadyToShow
        win 
    
    onMoveWin: (event) => event.sender.webContents.send 'saveBounds'
    
    # 00000000   00000000   0000000  000  0000000  00000000
    # 000   000  000       000       000     000   000     
    # 0000000    0000000   0000000   000    000    0000000 
    # 000   000  000            000  000   000     000     
    # 000   000  00000000  0000000   000  0000000  00000000
    
    onResizeWin: (event) => 
    
    onCloseWin: (event) =>
        
    otherInstanceStarted: (args, dir) =>
        if not visibleWins().length
            @toggleWindows()
            
    quit: => 
        @closeWindows()
        app.exit 0
        process.exit 0
        
    showAbout: => about img: "#{__dirname}/../img/about.png", pkg: pkg

#  0000000   00000000   00000000         0000000   000   000
# 000   000  000   000  000   000       000   000  0000  000
# 000000000  00000000   00000000        000   000  000 0 000
# 000   000  000        000        000  000   000  000  0000
# 000   000  000        000        000   0000000   000   000

app.on 'ready', -> kaliapp = new KaliApp
app.on 'window-all-closed', -> kaliapp.quit()
    
app.setName pkg.productName

module.exports = KaliApp

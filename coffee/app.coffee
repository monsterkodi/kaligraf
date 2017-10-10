
#  0000000   00000000   00000000   
# 000   000  000   000  000   000  
# 000000000  00000000   00000000   
# 000   000  000        000        
# 000   000  000        000        

{ about, prefs, post, noon, fs, log } = require 'kxk'

pkg      = require '../package.json'
Menu     = require './menu'
electron = require 'electron'
colors   = require 'colors'

app      = electron.app
Window   = electron.BrowserWindow
ipc      = electron.ipcMain

kaliapp  = undefined # < created in app.on 'ready'

#  0000000   00000000    0000000    0000000
# 000   000  000   000  000        000     
# 000000000  0000000    000  0000  0000000 
# 000   000  000   000  000   000       000
# 000   000  000   000   0000000   0000000 

args  = require('karg') """

#{pkg.productName}
    
    filelist  . ? files to open           . **
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

win         = null
wins        = -> Window.getAllWindows()
activeWin   = -> Window.getFocusedWindow()
visibleWins = -> (w for w in wins() when w?.isVisible() and not w?.isMinimized())
winWithID   = (winID) -> Window.fromId winID

# 000  00000000    0000000
# 000  000   000  000     
# 000  00000000   000     
# 000  000        000     
# 000  000         0000000

post.on 'toggleDevTools', => win.browserWindow.toggleDevTools()
post.on 'maximizeWindow', => kaliapp.maximizeWindow()
                        
# 000   000   0000000   000      000   0000000   00000000   00000000     
# 000  000   000   000  000      000  000   000  000   000  000   000    
# 0000000    000000000  000      000  000000000  00000000   00000000     
# 000  000   000   000  000      000  000   000  000        000          
# 000   000  000   000  0000000  000  000   000  000        000          

class KaliApp
    
    constructor: () -> 
        
        prefs.init()
        
        app.setName pkg.productName
                                
        @createWindow()

        Menu.init @

    # 000   000  000  000   000  0000000     0000000   000   000   0000000
    # 000 0 000  000  0000  000  000   000  000   000  000 0 000  000     
    # 000000000  000  000 0 000  000   000  000   000  000000000  0000000 
    # 000   000  000  000  0000  000   000  000   000  000   000       000
    # 00     00  000  000   000  0000000     0000000   00     00  0000000 

    reloadWin: (win) -> win?.webContents.reloadIgnoringCache()

    maximizeWindow: ->
        
        if win?
            if win.isMaximized()
                win.unmaximize() 
            else
                win.maximize()        
        else
            @showWindows()             

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
        
    screenSize: -> electron.screen.getPrimaryDisplay().workAreaSize
                    
    #  0000000  00000000   00000000   0000000   000000000  00000000
    # 000       000   000  000       000   000     000     000     
    # 000       0000000    0000000   000000000     000     0000000 
    # 000       000   000  000       000   000     000     000     
    #  0000000  000   000  00000000  000   000     000     00000000
       
    createWindow: ->
        
        bounds = prefs.get 'bounds', null
        if not bounds
            {w, h} = @screenSize()
            bounds = {}
            bounds.width = w
            bounds.height = h
            bounds.x = 0
            bounds.y = 0
            
        win = new Window
            x:               bounds.x
            y:               bounds.y
            width:           bounds.width
            height:          bounds.height
            minWidth:        556
            minHeight:       206
            useContentSize:  true
            fullscreenable:  false
            fullscreen:      false
            show:            false
            backgroundColor: '#111'
            titleBarStyle:   'hidden'

        win.loadURL "file://#{__dirname}/index.html"
        
        win.on 'move',   @saveBounds
        win.on 'resize', @saveBounds     
        
        winReadyToShow = =>
            win.show()
            win.focus()
             
            if args.DevTools then win.webContents.openDevTools()
                        
        win.on 'ready-to-show', winReadyToShow
        win
    
    saveBounds: (event) -> prefs.set 'bounds', event.sender.getBounds()
        
    quit: => 
        prefs.save()
        w.close() for w in wins()
        app.exit 0
        process.exit 0
        
    showAbout: => about
        img: "#{__dirname}/../bin/about.svg"
        pkg: pkg
        imageWidth:    '230px'
        imageHeight:   '230px'
        imageOffset:   '32px'
        versionOffset: '15px'
        highlight:     '#88f'

#  0000000   00000000   00000000         0000000   000   000
# 000   000  000   000  000   000       000   000  0000  000
# 000000000  00000000   00000000        000   000  000 0 000
# 000   000  000        000        000  000   000  000  0000
# 000   000  000        000        000   0000000   000   000

app.on 'ready', -> kaliapp = new KaliApp
app.on 'activate', -> kaliapp.showWindows()
app.on 'window-all-closed', -> kaliapp.quit()
app.on 'open-file', (event, file) -> log "open file #{file}"
        
app.setName pkg.productName

module.exports = KaliApp

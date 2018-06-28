###
 0000000   00000000   00000000   
000   000  000   000  000   000  
000000000  00000000   00000000   
000   000  000        000        
000   000  000        000
###

{ post, app, about, args, prefs, noon, watch, childp, colors, slash, fs, log } = require 'kxk'

pkg      = require '../package.json'
electron = require 'electron'
kaliapp  = null

# 000   000   0000000   000      000   0000000   00000000   00000000     
# 000  000   000   000  000      000  000   000  000   000  000   000    
# 0000000    000000000  000      000  000000000  00000000   00000000     
# 000  000   000   000  000      000  000   000  000        000          
# 000   000  000   000  0000000  000  000   000  000        000          

class KaliApp extends app
    
    constructor: -> 

        super
            dir:        __dirname
            pkg:        pkg
            index:      './index.html'
            icon:       '../img/app.ico'
            tray:       '../img/menu@2x.png'
            about:      '../img/about.svg'
            onShow:     -> kaliapp.onShow()
            width:      1000
            height:     1000
            minWidth:   556
            minHeight:  206
            args: """
                filelist  files to open                 **
                """

        if args.verbose
            log colors.white.bold "\n#{pkg.productName}", colors.gray "v#{pkg.version}\n"
            log colors.yellow.bold 'process'
            p = cwd: process.cwd()
            log noon.stringify p, colors:true
            log colors.yellow.bold 'args'
            log noon.stringify args, colors:true
            log ''
                    
    #  0000000  00000000   00000000   0000000   000000000  00000000
    # 000       000   000  000       000   000     000     000     
    # 000       0000000    0000000   000000000     000     0000000 
    # 000       000   000  000       000   000     000     000     
    #  0000000  000   000  00000000  000   000     000     00000000
       
    onShow: ->
        
        { width, height } = @screenSize()
        
        @opt.width  = width
        @opt.height = height
        
        @showWindow()
        
#  0000000   00000000   00000000         0000000   000   000
# 000   000  000   000  000   000       000   000  0000  000
# 000000000  00000000   00000000        000   000  000 0 000
# 000   000  000        000        000  000   000  000  0000
# 000   000  000        000        000   0000000   000   000

electron.app.on 'activate', -> kaliapp.showWindows()
electron.app.on 'open-file', (event, file) -> log "open file #{file}"
# electron.app.on 'window-all-closed', -> kaliapp.quit()
        
kaliapp = new KaliApp

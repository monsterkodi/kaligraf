
# 00     00   0000000   000  000   000
# 000   000  000   000  000  0000  000
# 000000000  000000000  000  000 0 000
# 000 0 000  000   000  000  000  0000
# 000   000  000   000  000  000   000

{ about, post, noon, childp, colors, fs, log, $, _ } = require 'kxk'

electron = require 'electron'
Kali     = require './kali'

class Main

    constructor: (element) ->

        element = $(element) if not _.isElement element
        
        post.setMaxListeners 100
        post.on 'slog', (t) -> window.logview?.appendText t
        
        @kali = new Kali element:element, app:not window.area?
        @kali.setStyle 'style'
        
        if @kali.app
            window.onresize = => @onResize window.innerWidth, window.innerHeight
        else
            window.area.on 'resized', @onResize
                
    onResize: (w, h) => 
        
        log "onResize #{w} #{h}"
        
        if @kali.stage.virgin
            delete @kali.stage.virgin
            reset = => @kali.stage.resetView @kali.stage.zoom 
            reset()
            setTimeout reset, 100
        else
            @kali.stage.resetSize()

    toggleMaximize: ->
        
        return if not @kali.app
        
        win = electron.remote.getCurrentWindow()
        electron.ipcRenderer.send 'maximizeWindow', win.id
            
    start: ->

module.exports = Main

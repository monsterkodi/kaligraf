
# 00     00   0000000   000  000   000
# 000   000  000   000  000  0000  000
# 000000000  000000000  000  000 0 000
# 000 0 000  000   000  000  000  0000
# 000   000  000   000  000  000   000

{ post, log } = require 'kxk'

Kali = require './kali'

class Main

    constructor: (element) ->

        post.setMaxListeners 100
        post.on 'slog', (t) -> window.logview.appendText t
        
        @kali = new Kali element: element  
        @kali.setStyle 'style'
        
        window.area.on 'resized', (w, h)  => 
            if @kali.stage.virgin
                delete @kali.stage.virgin
                reset = => @kali.stage.resetView @kali.stage.zoom 
                reset()
                setTimeout reset, 100
            else
                @kali.stage.resetSize()
                                
    start: ->
                
module.exports = Main

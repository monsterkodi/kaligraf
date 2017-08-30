
# 00     00   0000000   000  000   000
# 000   000  000   000  000  0000  000
# 000000000  000000000  000  000 0 000
# 000 0 000  000   000  000  000  0000
# 000   000  000   000  000  000   000

{ post, log } = require 'kxk'

Kali = require './kali'

class Main

    constructor: (element) ->

        post.on 'slog', (t) -> window.logview.appendText t
        
        @kali = new Kali element: element  
        @kali.setStyle 'style'
                                
    start: ->
                
module.exports = Main

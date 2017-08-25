
# 00     00   0000000   000  000   000
# 000   000  000   000  000  0000  000
# 000000000  000000000  000  000 0 000
# 000 0 000  000   000  000  000  0000
# 000   000  000   000  000  000   000

{log,post} = require 'kxk'
Controller = require './controller'

class Main

    constructor: (element) ->

        @controller = new Controller element: element  
        @controller.setStyle 'style'
        @controller.setMenu [
            
            button: 'Picker'
            click: (button) -> post.emit 'picker', 'toggle'
        ]
                
    start: ->
                
module.exports = Main

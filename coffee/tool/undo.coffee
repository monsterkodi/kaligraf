
# 000   000  000   000  0000000     0000000   
# 000   000  0000  000  000   000  000   000  
# 000   000  000 0 000  000   000  000   000  
# 000   000  000  0000  000   000  000   000  
#  0000000   000   000  0000000     0000000   

{ post, log, _ } = require 'kxk'

Tool = require './tool'

class Undo extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @undo = @stage.undo
                        
        @initTitle 'Undo'
        
        @initButtons [
            text:   '<'
            name:   'undo'
            action: @undo.undo
        ,
            text:   '>'
            name:   'redo'
            action: @undo.redo
        ]
        
        @initButtons [
            name:   'undos'
            action: @undo.undoAll
        ,
            name:   'redos'
            action: @undo.redoAll
        ]
        
        post.on 'undo', @onUndo
        
    onUndo: (info) => log 'onUndo', info
    
module.exports = Undo

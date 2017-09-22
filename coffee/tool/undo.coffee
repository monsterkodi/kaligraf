
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
                        
        @initTitle()
        
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
            text:   '0'
            name:   'undos'
            action: @undo.undoAll
        ,
            text:   '0'
            name:   'redos'
            action: @undo.redoAll
        ]
        
        post.on 'undo', @onUndo
        
    onUndo: (info) => 
        
        @button('undos').innerHTML = info.undos
        @button('redos').innerHTML = info.redos
    
module.exports = Undo

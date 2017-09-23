
#  0000000  000   000   0000000   000   000  
# 000       000   000  000   000  000 0 000  
# 0000000   000000000  000   000  000000000  
#      000  000   000  000   000  000   000  
# 0000000   000   000   0000000   00     00  

{ prefs, log, _ } = require 'kxk'

Tool = require './tool'

class Show extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @stage.ids = Show.ids.bind @stage
        
        @initTitle()
                
        @initButtons [
            text:   'IDs'
            name:   'ids'
            action: @stage.ids
            toggle: prefs.get 'stage:ids', false
        ]
        
    execute: -> 

    #  0000000  000000000   0000000    0000000   00000000    
    # 000          000     000   000  000        000         
    # 0000000      000     000000000  000  0000  0000000     
    #      000     000     000   000  000   000  000         
    # 0000000      000     000   000   0000000   00000000    
            
    @ids: -> 
    
        ids = prefs.get 'stage:ids', false
        ids = !ids
        prefs.set 'stage:ids', ids
        
        @selection.showIDs ids
    
module.exports = Show

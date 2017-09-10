
# 0000000     0000000   000000000   0000000  00000000  000    
# 000   000  000   000     000     000       000       000    
# 000   000  000   000     000     0000000   0000000   000    
# 000   000  000   000     000          000  000       000    
# 0000000     0000000      000     0000000   00000000  0000000

{ empty, log, _ } = require 'kxk'

{ rectsIntersect } = require './utils'

class DotSel

    constructor: (@edit) ->

        @dots = []

    #  0000000  000      00000000   0000000   00000000   
    # 000       000      000       000   000  000   000  
    # 000       000      0000000   000000000  0000000    
    # 000       000      000       000   000  000   000  
    #  0000000  0000000  00000000  000   000  000   000  
    
    clear: ->
        
        for dot in @dots
            dot.ctrl.setSelected dot.dot, false
            
        @dots = []

    del: (dot) ->
        
        if dot in @dots
            dot.ctrl.setSelected dot.dot, false
            _.pull @dots, dot
        
    empty: -> empty @dots
            
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    add: (dot, keep=true) ->
        
        @clear() if not keep
        
        dot.ctrl.setSelected dot.dot, true
        
        if dot not in @dots then @dots.push dot

    addInRect: (object, r, o) ->
        
        for dot in object.dots()
            rb = dot.rbox()
            if rectsIntersect r, rb
                @add dot, o.join

    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveBy: (delta) ->
        
        for dot in @dots
            ctrl   = dot.ctrl
            index  = ctrl.index()
            if index < 0
                log 'selected ctrl not in object?', index
                continue 
            object = ctrl.object
            oldPos = object.dotPos index, dot.dot
            if not oldPos.plus?
                log "dafuk? #{index} #{dot.dot}"
            newPos = oldPos.plus delta
            object.movePoint index, newPos, dot.dot
            object.plot()
                
module.exports = DotSel

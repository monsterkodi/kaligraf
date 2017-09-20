
# 000   000  000   000  0000000     0000000 
# 000   000  0000  000  000   000  000   000
# 000   000  000 0 000  000   000  000   000
# 000   000  000  0000  000   000  000   000
#  0000000   000   000  0000000     0000000 

{ first, last, empty, resolve, fs, str, log, _ } = require 'kxk'

Object = require './object'

class Undo

    constructor: (@kali) ->
        
        @stage = @kali.stage
        
        @clear()

    #  0000000  000      00000000   0000000   00000000   
    # 000       000      000       000   000  000   000  
    # 000       000      0000000   000000000  0000000    
    # 000       000      000       000   000  000   000  
    #  0000000  0000000  00000000  000   000  000   000  
    
    clear: -> 
        
        @history = []
        @futures = []
        
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    start: (object, action) ->
        
        @futures = []
        
        state = @state 'start', object
        state.action = action
        prev = last @history
        
        if @sameState(state, prev) and prev.type != 'start'
            log 'sameState!'
        else   
            if action? and prev? and action == prev.action and prev.type != 'start'
                @history.splice @history.length-1, 1, state
            @history.push state
            
        @log 'START'
            
    # 00000000  000   000  0000000    
    # 000       0000  000  000   000  
    # 0000000   000 0 000  000   000  
    # 000       000  0000  000   000  
    # 00000000  000   000  0000000    
    
    end: (object) ->

        prev   = last @history
        state  = @state 'end', object
        state.action = prev.action
        if prev.action? and prev.type != 'start'
            @history.splice @history.length-1, 1, state
        else   
            @history.push state
            
        @log 'END'
            
    #  0000000  000000000   0000000   000000000  00000000  
    # 000          000     000   000     000     000       
    # 0000000      000     000000000     000     0000000   
    #      000     000     000   000     000     000       
    # 0000000      000     000   000     000     00000000  
    
    state: (type, object) ->

        state =
            type:   type
            class:  object.constructor.name
        
        if object instanceof Object
            
            state.id     = object.item.id()
            state.points = object.points()
            
        else
            
            state.svg = @stage.getSVG()
            
        state

    sameState: (a,b) ->
        
        same = a? and b? and a.id == b.id and a.action? and a.action == b.action
        same and _.isEqual a.points, b.points
        
    # 000   000  000   000  0000000     0000000   
    # 000   000  0000  000  000   000  000   000  
    # 000   000  000 0 000  000   000  000   000  
    # 000   000  000  0000  000   000  000   000  
    #  0000000   000   000  0000000     0000000   
    
    undo: -> 
        
        return if empty @history
        
        @futures.unshift @history.pop()
        
        while last(@history)? and last(@history).type != 'start'
            @futures.unshift @history.pop()
            
        @apply last @history
        
        # @dump() if empty @history
        
        @log 'UNDO'
        
    # 00000000   00000000  0000000     0000000   
    # 000   000  000       000   000  000   000  
    # 0000000    0000000   000   000  000   000  
    # 000   000  000       000   000  000   000  
    # 000   000  00000000  0000000     0000000   
    
    redo: -> 
        
        return if empty @futures
        
        @history.push @futures.shift()
        
        while last(@history)?.type == 'start'
            @history.push @futures.shift()
            
        @apply last @history
        
        # @dump() if empty @futures
        
        @log 'REDO'
    
    #  0000000   00000000   00000000   000      000   000  
    # 000   000  000   000  000   000  000       000 000   
    # 000000000  00000000   00000000   000        00000    
    # 000   000  000        000        000         000     
    # 000   000  000        000        0000000     000     
    
    apply: (state) ->
        
        return if not state?

        if state.class == 'Object'
            
            item = SVG.get state.id
            item.plot state.points
            
        else
            
            @stage.setSVG state.svg

    # 0000000    000   000  00     00  00000000   
    # 000   000  000   000  000   000  000   000  
    # 000   000  000   000  000000000  00000000   
    # 000   000  000   000  000 0 000  000        
    # 0000000     0000000   000   000  000        
    
    dump: ->
        
        log @history
        log @futures
        
        svg  = str(@history.filter (h) -> h.class != 'Object') 
        svg += str(@futures.filter (h) -> h.class != 'Object')
        
        fs.writeFile resolve('~/Desktop/history.html'), svg, ->
            
    log: (msg) ->
        log msg
        log @history.map((i) -> i.class + ' ' + i.action + ' ' + i.type).join '\n'
        
module.exports = Undo

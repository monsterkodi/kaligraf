
# 000   000  000   000  0000000     0000000 
# 000   000  0000  000  000   000  000   000
# 000   000  000 0 000  000   000  000   000
# 000   000  000  0000  000   000  000   000
#  0000000   000   000  0000000     0000000 

{ post, first, last, empty, resolve, fs, str, log, _ } = require 'kxk'

Object = require './object'

class Undo

    constructor: (@kali) ->
        
        @stage = @kali.stage
        
        post.on 'stage', @onStage
        
        @clear()

    #  0000000  000      00000000   0000000   00000000   
    # 000       000      000       000   000  000   000  
    # 000       000      0000000   000000000  0000000    
    # 000       000      000       000   000  000   000  
    #  0000000  0000000  00000000  000   000  000   000  
    
    clear: ->
        
        @history   = []
        @futures   = []
        @savePoint = 0
        @post 'clear'
       
    onStage: (action) =>
        
        if action == 'save'
            @savePoint = @history.length
            @post 'save'
        
    # 0000000     0000000   
    # 000   000  000   000  
    # 000   000  000   000  
    # 000   000  000   000  
    # 0000000     0000000   
    
    do: (object, action) ->
        
        @futures = []
        
        state = @state 'start', object
        state.action = action
        prev = last @history
        
        if @sameState(state, prev) and prev.type != 'start'
            # log 'sameState!'
        else   
            if action? and prev? and action == prev.action and prev.type != 'start'
                @history.splice @history.length-1, 1, state
            @history.push state
            
        @post 'do'
            
    # 0000000     0000000   000   000  00000000
    # 000   000  000   000  0000  000  000     
    # 000   000  000   000  000 0 000  0000000 
    # 000   000  000   000  000  0000  000     
    # 0000000     0000000   000   000  00000000
    
    done: (object) ->

        prev  = last @history
        state = @state 'end', object
        state.action = prev.action
        if prev.action? and prev.type != 'start'
            @history.splice @history.length-1, 1, state
        else   
            @history.push state
          
        @post 'done'
                    
    # 000   000  000   000  0000000     0000000   
    # 000   000  0000  000  000   000  000   000  
    # 000   000  000 0 000  000   000  000   000  
    # 000   000  000  0000  000   000  000   000  
    #  0000000   000   000  0000000     0000000   
    
    undo: => 
        
        return if empty @history
        
        while last(@history)? and last(@history).type != 'start'
            @futures.unshift @history.pop()
            
        @apply last @history
        
        @futures.unshift @history.pop()
        
        @post 'undo'
        
    undoAll: =>
        
        return if empty @history
        
        @futures = @history.concat @futures
        @history = []
        
        @apply first @futures
        
        @post 'undo'
        
    # 00000000   00000000  0000000     0000000   
    # 000   000  000       000   000  000   000  
    # 0000000    0000000   000   000  000   000  
    # 000   000  000       000   000  000   000  
    # 000   000  00000000  0000000     0000000   
    
    redo: => 
        
        return if empty @futures
        
        @history.push @futures.shift()
        
        while last(@history)?.type == 'start'
            @history.push @futures.shift()
            
        @apply last @history
        
        @post 'redo'
        
    redoAll: =>
        
        return if empty @futures
        
        @history = @history.concat @futures
        @futures = []
        
        @apply last @history
        
        @post 'redo'        
    
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
            
        @stage.restore state.stage

    # 00000000    0000000    0000000  000000000  
    # 000   000  000   000  000          000     
    # 00000000   000   000  0000000      000     
    # 000        000   000       000     000     
    # 000         0000000   0000000      000     
    
    post: (action) ->
        
        @log "post #{action}"
        
        info = 
            action: action
            undos:  @undos()
            redos:  @redos()
            dirty:  @savePoint != @history.length
                
        post.emit 'undo', info

    undos: -> 
        undos = @history.filter (state) -> state.type == 'start'
        undos.length
        
    redos: -> 
        redos = @futures.filter (state) -> state.type == 'end'
        redos.length
        
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
            
        state.stage = @stage.state()
            
        state

    sameState: (a,b) ->
        
        same = a? and b? and a.id == b.id and a.action? and a.action == b.action
        same and _.isEqual(a.points, b.points) and _.isEqual(a.stage, b.stage)
        
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
        
        # log msg
        # log @history.map((i) -> i.class + ' ' + i.action + ' ' + i.type).join '\n'
        # log @futures.map((i) -> i.class + ' ' + i.action + ' ' + i.type).join '\n'
        
module.exports = Undo


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
        
        @history = []
        @futures = []
        
    undo: -> 
        
        return if empty @history
        
        @futures.unshift @history.pop()
        
        while last(@history)?.type == 'stop'
            @futures.unshift @history.pop()
            
        @apply last @history
        
        @dump() if empty @history
        
    redo: -> 
        
        return if empty @futures
        
        @history.push @futures.shift()
        
        while last(@history)?.type == 'start'
            @history.push @futures.shift()
            
        @apply last @history
        
        @dump() if empty @futures
    
    apply: (state) ->
        
        return if not state?

        if state.class == 'Object'
            
            item = SVG.get state.id
            item.plot state.points
            
        else
            
            @stage.setSVG state.svg

    dump: ->
        
        log @history
        log @futures
        
        svg  = str(@history.filter (h) -> h.class != 'Object') 
        svg += str(@futures.filter (h) -> h.class != 'Object')
        
        fs.writeFile resolve('~/Desktop/history.html'), svg, ->
            
    start: (object) ->
        
        @futures = []
        
        state = @state 'start', object
            
        if @sameState state, last @history
            last(@history).type = 'startstop'
        else   
            @history.push state
            
    stop: (object) ->

        @history.push @state 'stop', object
            
    state: (type, object) ->

        state =
            type:   type
            class:  object.constructor.name
        
        if object instanceof Object
            
            state.id =     object.item.id()
            state.points = object.points()
            
        else
            
            state.svg = @stage.getSVG()
            
        state
                        
    sameState: (a,b) ->
        
        a? and b? and a.id == b.id and _.isEqual a.points, b.points
        
module.exports = Undo

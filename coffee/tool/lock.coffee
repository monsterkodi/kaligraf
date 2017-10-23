
# 000       0000000    0000000  000   000  
# 000      000   000  000       000  000   
# 000      000   000  000       0000000    
# 000      000   000  000       000  000   
# 0000000   0000000    0000000  000   000  

{ post, first, last, prefs, valid, empty, log, _ } = require 'kxk'

{ uuid } = require '../utils'

Tool   = require './tool'
Points = require '../edit/points'

class Lock extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @trans  = @kali.trans
        @shapes = @stage.shapes
        
        @locklist = []
        @white = {}
        @black = {}
        @locks = {}
        
        @initTitle()
        
        @initButtons [
            action: @onLock
            name:   'lock'
            icon:   'lock-lock'
        ,
            action: @onUnlock
            name:   'unlock'
            icon:   'lock-unlock'
        ]
        
        post.on 'stage',  @onStage
        post.on 'object', @onObject
        post.on 'dotsel', @onDotSel
        post.on 'edit',   @onEdit

    # 00000000  0000000    000  000000000  
    # 000       000   000  000     000     
    # 0000000   000   000  000     000     
    # 000       000   000  000     000     
    # 00000000  0000000    000     000     
    
    onEdit: (action, info) =>
        
        switch action
            when 'addObject' then @addObject info.object
            when 'delObject' then @delObject info.object
            
    onObject: (action, info) =>
        
        switch action
            when 'setPoint'  then @updateObject info.object
            
    onDotSel: (action, info) =>
        
        switch action
            when 'move'
                return if empty @locklist
                dots = info.dotsel.dots.filter (dot) -> dot.dot == 'point'
                movedIds = dots.map (dot) => @dotId dot
                @moveLockedIdsBy movedIds, info.delta, info.event

    onStage: (action, info) =>
        
        switch action
            when 'load', 'restore'  then @loadLocks()
            when 'clear'            then @clear()
            when 'moveItems'        then @moveItemsBy info.items, info.delta
            when 'viewbox'
                for k,lock of @locks
                    lock.transform(scale: 1.0/@stage.zoom).transform rotation: 45
                
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveItemsBy: (items, delta) ->
        
        return if empty @locklist
        movedIds = []
        for item in items
            movedIds = movedIds.concat @idsForItem item
        @moveLockedIdsBy movedIds, delta
            
    moveLockedIdsBy: (movedIds, delta, event) ->
        
        locks = @locksForIDs movedIds
        
        return if empty locks
        
        lockedIds = _.flatten locks
        _.pullAll lockedIds, movedIds
        
        if valid(lockedIds) and not event?.metaKey

            itemIndexDots = {}
            
            for id in lockedIds
                
                split = @splitId id 
                item  = SVG.get split.id
                
                if not item?
                    log 'Lock.moveLockedIdsBy -- missing item?', split
                    continue
                
                index = split.index
                
                itemIndexDots[split.id] ?= item:item, indexDots:[]
                itemIndexDots[split.id].indexDots.push index:index, dots:['point']
                
            for id,itemIndexDot of itemIndexDots
                
                points = new Points @kali, itemIndexDot.item
                points.moveIndexDots 
                    indexDots:  itemIndexDot.indexDots
                    delta:      delta
                    event:      event
                
        for lock in locks
            @updateLock lock
            
        @shapes.edit?.update()
            
    #  0000000   0000000          000  00000000   0000000  000000000  
    # 000   000  000   000        000  000       000          000     
    # 000   000  0000000          000  0000000   000          000     
    # 000   000  000   000  000   000  000       000          000     
    #  0000000   0000000     0000000   00000000   0000000     000     
    
    addObject: (object) -> @updateObject object

    delObject: (object) ->
        
        for lock in @locksForItem object.item
            for id in lock
                @delLine id
    
    updateObject: (object) ->
        
        for lock in @locksForItem object.item
            @updateLock lock

    clear: ->
        
        @locklist = []
        @white = {}
        @black = {}
        @locks = {}
            
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    updateLock: (lock) ->
        
        return if not @shapes.edit?
        
        if not @locks[lock[0]]?
            @locks[lock[0]] = @shapes.edit.linesWhite.rect 12, 12
            @locks[lock[0]].addClass 'lock'
            @locks[lock[0]].transform(scale: 1.0/@stage.zoom).transform rotation: 45
            
        firstItem = SVG.get @splitId(lock[0]).id 
        pos0 = @trans.pointPos firstItem, @splitId(lock[0]).index
        @trans.center @locks[lock[0]], pos0
        
        for index in [1...lock.length]
            
            prev = @splitId lock[index-1]
            next = @splitId lock[index]
            
            prevItem = SVG.get prev.id 
            nextItem = SVG.get next.id 
            
            if not prevItem or not nextItem
                log "Lock.updateLock -- missing items at index #{index} in lock:", lock
                continue
                
            pos1 = @trans.pointPos prevItem, prev.index
            pos2 = @trans.pointPos nextItem, next.index
            
            if not @locks[lock[index]]?
                @locks[lock[index]] = @shapes.edit.linesWhite.rect 12, 12
                @locks[lock[index]].addClass 'lock'
                @locks[lock[index]].transform(scale: 1.0/@stage.zoom).transform rotation: 45
                
            if not @white[lock[index]]?
                @white[lock[index]] = @shapes.edit.linesWhite.line()
                
            if not @black[lock[index]]?
                @black[lock[index]] = @shapes.edit.linesBlack.line()
            
            @trans.center @locks[lock[index]], pos2
            @white[lock[index]].plot [[pos1.x, pos1.y], [pos2.x, pos2.y]]
            @black[lock[index]].plot [[pos1.x, pos1.y], [pos2.x, pos2.y]]                
                                                
    # 000       0000000    0000000  000   000   0000000   0000000    000      00000000  
    # 000      000   000  000       000  000   000   000  000   000  000      000       
    # 000      000   000  000       0000000    000000000  0000000    000      0000000   
    # 000      000   000  000       000  000   000   000  000   000  000      000       
    # 0000000   0000000    0000000  000   000  000   000  0000000    0000000  00000000  
    
    lockableDots: ->
        
        if @shapes.edit? and not @shapes.edit.dotsel.empty()
            @shapes.edit.dotsel.dots.filter (dot) -> dot.dot == 'point'
        else
            []

    #  0000000   0000000   000   000  00000000  
    # 000       000   000  000   000  000       
    # 0000000   000000000   000 000   0000000   
    #      000  000   000     000     000       
    # 0000000   000   000      0      00000000  
    
    saveLocks: ->
    
        locks = SVG.get 'locks'
        locks ?= @stage.svg.defs().element 'locks' 
        locks.id 'locks'
        if empty @locklist
            locks.node.innerHTML = ''
        else
            locks.node.innerHTML = @locklist.map((ll) -> ll.join ',').join '\n'
            
        # log 'saveLocks', @locklist
        
    # 000       0000000    0000000   0000000    
    # 000      000   000  000   000  000   000  
    # 000      000   000  000000000  000   000  
    # 000      000   000  000   000  000   000  
    # 0000000   0000000   000   000  0000000    
    
    loadLocks: ->
        
        locks = SVG.get 'locks'
        if locks?
            @locklist = locks.node.innerHTML.split('\n').map (ll) -> ll.split ','
            @locklist = @locklist.filter (ll) -> ll? and ll.length > 1
        else
            @locklist = []
            
        # log 'loadLocks', @locklist
            
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    addDotToLock: (dot, lock) ->
        
        if not @lockContainsDot lock, dot
            lock.push @dotId dot
            @updateLock lock
            
    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    delDotFromLock: (dot, lock) ->

        id = @dotId dot
        @delLine id
        _.pull lock, id
        if lock.length == 1
            @delLine first lock
            _.pull @locklist, lock
            
    delLine: (id) ->
        
        @white[id]?.remove()
        @black[id]?.remove()
        @locks[id]?.remove()
        delete @white[id]
        delete @black[id]
        delete @locks[id]
            
    #  0000000   00000000  000000000    
    # 000        000          000       
    # 000  0000  0000000      000       
    # 000   000  000          000       
    #  0000000   00000000     000       
            
    lockContainsDot: (lock, dot) -> @dotId(dot) in lock
    lockContainsItem: (lock, item) -> item in @itemsForLock lock
    itemsForLock: (lock) ->
        ids = _.uniq lock.map (l) -> l.split(':')[0]
        ids.map (id) -> SVG.get id

    lockForID: (id) ->
        if valid(@locklist) 
            for lock in @locklist
                return lock if id in lock
        
    lockForDot: (dot) ->
        
        if valid(@locklist) and dot.dot == 'point'
            for lock in @locklist
                if @lockContainsDot lock, dot
                    return lock
                    
    locksForDots: (dots) ->
        
        locks = _.uniq dots.map (dot) => @lockForDot dot
        locks = locks.filter (lock) -> lock?
                    
    locksForIDs: (ids) ->
        
        locks = _.uniq ids.map (id) => @lockForID id
        locks = locks.filter (lock) -> lock?
        
    locksForItem: (item) ->
        
        @locklist.filter (lock) => @lockContainsItem lock, item
        
    idsForItem: (item) ->
        
        if points = Points.itemPoints item
            points.map (point) -> item.id() + ':' + points.indexOf point
        else if item.type in ['g']
            ids = []
            for child in item.children()
                ids = ids.concat @idsForItem child
            ids
    
    # 000  0000000    
    # 000  000   000  
    # 000  000   000  
    # 000  000   000  
    # 000  0000000    
    
    dotId: (dot) -> dot.ctrl.object.item.id() + ':' + dot.ctrl.index()
    splitId: (id) -> 
        split = id.split ':'
        id:     split[0]
        index:  parseInt split[1]
            
    # 000       0000000    0000000  000   000  
    # 000      000   000  000       000  000   
    # 000      000   000  000       0000000    
    # 000      000   000  000       000  000   
    # 0000000   0000000    0000000  000   000  
    
    onLock: => 
        
        dots = @lockableDots()
        return if dots.length < 2
        
        for dot in dots
            if lock = @lockForDot dot
                break
        
        @stage.do 'lock'
        if not lock
            lock = []
            @locklist.push lock
            
        for dot in dots
            @addDotToLock dot, lock
            
        @saveLocks()
        @stage.done()
        
    # 000   000  000   000  000       0000000    0000000  000   000  
    # 000   000  0000  000  000      000   000  000       000  000   
    # 000   000  000 0 000  000      000   000  000       0000000    
    # 000   000  000  0000  000      000   000  000       000  000   
    #  0000000   000   000  0000000   0000000    0000000  000   000  
    
    onUnlock: =>

        @stage.do 'unlock'
        for dot in @lockableDots()
            if lock = @lockForDot dot
                @delDotFromLock dot, lock
            
        @saveLocks()
        @stage.done()
    
module.exports = Lock

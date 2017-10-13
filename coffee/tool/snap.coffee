
#  0000000  000   000   0000000   00000000   
# 000       0000  000  000   000  000   000  
# 0000000   000 0 000  000000000  00000000   
#      000  000  0000  000   000  000        
# 0000000   000   000  000   000  000        

{ elem, prefs, empty, first, valid, clamp, post, pos, log, _ } = require 'kxk'

{ itemIDs, growBox, boxOffset, bboxForItems, scaleBox, moveBox, setBox, itemBox } = require '../utils'

Tool = require './tool'

class Snap extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @trans = @kali.trans
        
        @div = elem 'div', id: 'snapDiv'
        @kali.insertAboveSelection @div
        
        @svg = SVG(@div).size '100%', '100%' 
        @svg.addClass 'snap'

        @visible  = prefs.get 'snap:visible', false
        @snapGrid = prefs.get 'snap:grid',    false
        @snapItem = prefs.get 'snap:item',    false
        
        @clear()
        
        @initTitle()
        
        @initButtons [
            name:   'grid'
            tiny:   'snap-grid'
            toggle: @snapGrid
            action: @onSnapGrid
        ,
            name:   'item'
            tiny:   'snap-item'
            toggle: @snapItem
            action: @onSnapItem
        ]
        
        @initButtons [
            name:   'show'
            tiny:   'snap-show'
            toggle: @visible
            action: @onShow
        ]
        
        @snapDist = clamp 1, 10, 5/@stage.zoom
        
        post.on 'stage', @onStage
        
    clear: -> 
        
        @svg.clear()
        @snapKeep = pos 0,0
        @winner = x:null, y:null
        
    onStage: (action, box) =>
        
        if action == 'viewbox' 
            @svg.viewbox box
            @snapDist = clamp 0.1, 20, 5/@stage.zoom

    # 000  000000000  00000000  00     00   0000000  0000000    00000000  000      000000000   0000000   
    # 000     000     000       000   000  000       000   000  000       000         000     000   000  
    # 000     000     0000000   000000000  0000000   000   000  0000000   000         000     000000000  
    # 000     000     000       000 0 000       000  000   000  000       000         000     000   000  
    # 000     000     00000000  000   000  0000000   0000000    00000000  0000000     000     000   000  
    
    itemsDelta: (items, oldDelta) -> 
        
        @svg.clear()
        
        delta = pos oldDelta
        
        if @snapGrid or @snapItem
            
            itemBoxes = items.map (item) => moveBox @trans.getRect(item), @snapKeep.times 1 
            
            for [orientation, attribs] in [['x' ,['x', 'cx', 'x2']], ['y', ['y', 'cy', 'y2']]]
                
                combis = []
                for a in attribs
                    for b in attribs
                        combis.push [a,b]
    
                closest = []
                for item in @stage.treeItems()
                    continue if item in items
                    abox = @trans.getRect item
                    minDist = Number.MAX_SAFE_INTEGER
                    for [a,b] in combis
                        for bbox in itemBoxes
                            dist = abox[a] - bbox[b] 
                            if Math.abs(dist) < @snapDist
                                closest.push dist:dist, a:a, b:b, val:abox[a], id:item.id()
                                
                if valid closest
                    
                    closest.sort (a,b) -> Math.abs(a.dist) - Math.abs(b.dist)
                    winner = first closest
                    
                    if @visible
                        val = winner.val
                        max = Number.MAX_SAFE_INTEGER
                        min = Number.MIN_SAFE_INTEGER
                        if orientation == 'x'
                            l = @svg.line val, min, val, max
                        else
                            l = @svg.line min, val, max, val
                        l.style 'stroke-width', 1/@stage.zoom
                    
                    if @winner[orientation] and @winner[orientation].id != winner.id
                        oldKeep = @snapKeep[orientation]
                        @snapKeep[orientation] = delta[orientation] - winner.dist
                        delta[orientation] = winner.dist + oldKeep
                    else 
                        if @snapKeep[orientation]
                            @snapKeep[orientation] += delta[orientation]
                            delta[orientation] = 0
                        else
                            @snapKeep[orientation] = delta[orientation]-winner.dist
                            delta[orientation] = winner.dist
                    
                    @winner[orientation] = winner
                    
                else
                    
                    delta[orientation] += @snapKeep[orientation]
                    @snapKeep[orientation] = 0
                    @winner[orientation] = null
        else
            @snapKeep = pos 0,0
            @winner = x:null, y:null
            
        delta
        
    onSnapItem: =>
        
        @snapItem = @button('item').toggle
        prefs.set 'snap:item', @snapItem
        
    onSnapGrid: =>
        
        @snapGrid = @button('grid').toggle
        prefs.set 'snap:grid', @snapGrid
        
    #  0000000  000   000   0000000   000   000  
    # 000       000   000  000   000  000 0 000  
    # 0000000   000000000  000   000  000000000  
    #      000  000   000  000   000  000   000  
    # 0000000   000   000   0000000   00     00  
    
    onShow: =>
        
        @visible = @button('show').toggle
        
        prefs.set 'snap:visible', @visible
            
        if @visible then @showSnap()
        else             @hideSnap()
        
    showSnap: ->
    hideSnap: -> 
        
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: =>
        
module.exports = Snap

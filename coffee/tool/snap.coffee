
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

        @visible    = prefs.get 'snap:visible', false
        @snapGrid   = prefs.get 'snap:grid',    false
        @snapBorder = prefs.get 'snap:border',  false
        @snapCenter = prefs.get 'snap:center',  false
        @snapDeep   = prefs.get 'snap:deep',    false
        
        @clear()
        
        @initTitle()
        
        @initButtons [
            name:   'grid'
            tiny:   'snap-grid'
            toggle: @snapGrid
            action: @onSnapGrid
        ,
            name:   'center'
            tiny:   'snap-center'
            toggle: @snapCenter
            action: @onSnapCenter
        ,
            name:   'border'
            tiny:   'snap-border'
            toggle: @snapBorder
            action: @onSnapBorder
        ]
        
        @initButtons [
            name:   'deep'
            tiny:   'snap-deep'
            toggle: @snapDeep
            action: @onSnapDeep
        ,    
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
        
        if @snapGrid or @snapCenter or @snapBorder
            
            if @snapDeep
                thisItems = []
                for item in items
                    thisItems = thisItems.concat @stage.treeItems item:item
            else
                thisItems = items
                
            itemBoxes = thisItems.map (item) => moveBox @trans.getRect(item), @snapKeep.times 1 
            
            attribList = [['x' ,[]], ['y', []]]
            if @snapCenter
                attribList[0][1].push 'cx'
                attribList[1][1].push 'cy'
            if @snapBorder
                attribList[0][1].push 'x'
                attribList[0][1].push 'x2'
                attribList[1][1].push 'y'
                attribList[1][1].push 'y2'
            
            for [orientation, attribs] in attribList
                
                combis = []
                for a in attribs
                    for b in attribs
                        combis.push [a,b]
    
                if @snapDeep
                    otherItems = @stage.treeItems pickable:true
                else
                    otherItems = @stage.pickableItems()

                closest = []
                for item in otherItems
                    continue if item in thisItems
                    if valid _.intersection item.parents(), thisItems
                        continue
                    abox = @trans.getRect item
                    minDist = Number.MAX_SAFE_INTEGER
                    for [a,b] in combis
                        for bbox in itemBoxes
                            dist = abox[a] - bbox[b] 
                            if Math.abs(dist) < @snapDist
                                closest.push dist:dist, a:a, b:b, val:abox[a], id:a+item.id(), item:item
                                
                if valid closest
                    
                    closest.sort (a,b) -> Math.abs(a.dist) - Math.abs(b.dist)
                    winner = first closest
                    
                    if @visible
                        while valid(closest) and Math.abs(first(closest).dist - winner.dist) < 0.001
                            close = closest.shift()
                            val = close.val
                            max = Number.MAX_SAFE_INTEGER
                            min = Number.MIN_SAFE_INTEGER
                            if orientation == 'x'
                                l = @svg.line val, min, val, max
                            else
                                l = @svg.line min, val, max, val
                            l.style 'stroke-width', 1/@stage.zoom
                            size = 6/@stage.zoom
                            center = @trans.center close.item
                            if close.a in ['cx', 'cy']
                                c = @svg.circle size
                                l.addClass 'snap-center'
                                c.addClass 'snap-center'
                                @trans.center c, center
                            else
                                r = @svg.rect size, size
                                switch close.a
                                    when 'x', 'x2' then center.x = val
                                    when 'y', 'y2' then center.y = val
                                @trans.center r, center
                    
                    if @winner[orientation]? and @winner[orientation].id != winner.id
                        oldKeep = @snapKeep[orientation]
                        @snapKeep[orientation] = delta[orientation]-winner.dist
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
        
    onSnapCenter: =>
        
        @snapCenter = @button('center').toggle
        prefs.set 'snap:center', @snapCenter

    onSnapBorder: =>
        
        @snapBorder = @button('border').toggle
        prefs.set 'snap:border', @snapBorder

    onSnapDeep: =>
        
        @snapDeep = @button('deep').toggle
        prefs.set 'snap:deep', @snapDeep
        
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

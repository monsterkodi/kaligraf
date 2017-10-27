
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
        @snapGaps   = prefs.get 'snap:gaps',    false
        
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
            name:   'gaps'
            tiny:   'snap-gaps'
            toggle: @snapGaps
            action: @onSnapGaps
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

    # 0000000     0000000   000   000        0000000    00000000  000      000000000   0000000   
    # 000   000  000   000   000 000         000   000  000       000         000     000   000  
    # 0000000    000   000    00000          000   000  0000000   000         000     000000000  
    # 000   000  000   000   000 000         000   000  000       000         000     000   000  
    # 0000000     0000000   000   000        0000000    00000000  0000000     000     000   000  
    
    boxDelta: (box, side, items, oldDelta) -> 
        
        @svg.clear()
        
        delta = pos oldDelta
        
        if @snapGrid or @snapCenter or @snapBorder or @snapGaps
                                    
            xyClosest = @calcClosestBox box, side, items
            for xy,closest of xyClosest
                                                                    
                if valid closest
                    
                    winner = first closest
                                        
                    if @winner[xy]? and @winner[xy].id != winner.id
                        oldKeep = @snapKeep[xy]
                        @snapKeep[xy] = delta[xy]-winner.dist
                        delta[xy] = winner.dist + oldKeep
                    else 
                        if @snapKeep[xy]
                            @snapKeep[xy] += delta[xy]
                            delta[xy] = 0
                        else
                            @snapKeep[xy] = delta[xy]-winner.dist
                            delta[xy] = winner.dist
                    
                    @winner[xy] = winner
                    
                    if @visible then @drawClosest xy, closest
                    
                else
                    
                    delta[xy] += @snapKeep[xy]
                    @snapKeep[xy] = 0
                    @winner[xy] = null
                    
        else
            @snapKeep = pos 0,0
            @winner = x:null, y:null
            
        delta

    #  0000000   0000000   000       0000000      0000000     0000000   000   000  
    # 000       000   000  000      000           000   000  000   000   000 000   
    # 000       000000000  000      000           0000000    000   000    00000    
    # 000       000   000  000      000           000   000  000   000   000 000   
    #  0000000  000   000  0000000   0000000      0000000     0000000   000   000  
    
    calcClosestBox: (box, side, thisItems) ->
        
        itemBox = _.clone box
                
        combis  = @combinations()
        
        if side.includes 'right'
            itemBox.x2    += @snapKeep.x
            itemBox.width += @snapKeep.x
            itemBox.w = itemBox.width
            combis.x = combis.x.filter (c) -> c[1] == 'x2'
        else if side.includes 'left'
            itemBox.x     += @snapKeep.x
            itemBox.width -= @snapKeep.x
            itemBox.w = itemBox.width
            combis.x = combis.x.filter (c) -> c[1] == 'x'
        else
            combis.x = []
            
        if side.includes 'bot'
            itemBox.y2     += @snapKeep.y
            itemBox.height += @snapKeep.y
            itemBox.h = itemBox.height
            combis.y = combis.y.filter (c) -> c[1] == 'y2'
        else if side.includes 'top'
            itemBox.y      += @snapKeep.y
            itemBox.height -= @snapKeep.y
            itemBox.h = itemBox.height
            combis.y = combis.y.filter (c) -> c[1] == 'y'
        else
            combis.y = []
            
        if @snapDeep
            otherItems = @stage.treeItems pickable:true
        else
            otherItems = @stage.pickableItems()
        
        otherItems = otherItems.filter (o) -> o not in thisItems and empty _.intersection o.parents(), thisItems
        otherBoxes = otherItems.map (item) => [item, @trans.getRect item]
            
        closest = x:[], y:[]
        
        gaps = @calcGaps otherBoxes
        
        for xy in 'xy'
            
            for [other,obox] in otherBoxes
                
                ibox = itemBox
                    
                for [a,b] in combis[xy]
                
                    dist = obox[a] - ibox[b]
                    dist = Math.round(dist*100)/100
                    
                    if Math.abs(dist) <= @snapDist
                        
                        closest[xy].push 
                            dist:   dist
                            a:      a
                            val:    obox[a]
                            item:   other
                            id:     a+other.id()

                continue if not @snapGaps or empty gaps[xy]

                oo = x:'cy', y:'cx'
                os = x:'h',  y:'w'
                
                continue if Math.abs(obox[oo[xy]]-ibox[oo[xy]]) > (obox[os[xy]]+ibox[os[xy]])/2
                
                ic = x:'x2', y:'y2'
                oc = x:'x',  y:'y'
                
                if obox[oc[xy]] > ibox[ic[xy]]
                    dist = obox[oc[xy]] - ibox[ic[xy]]
                    neg = 1
                else if ibox[oc[xy]] > obox[ic[xy]]
                    dist = ibox[oc[xy]] - obox[ic[xy]]
                    neg = -1
                else
                    continue
                 
                if xy == 'x' 
                    continue if neg < 0 and side.includes 'right'
                    continue if neg > 0 and side.includes 'left'
                else
                    continue if neg < 0 and side.includes 'bot'
                    continue if neg > 0 and side.includes 'top'
                        
                for gapDist,gap of gaps[xy]
                    
                    gapDiff = dist - gapDist
                    gapDiff *= neg
                    
                    if Math.abs(gapDiff) <= @snapDist
                        closest[xy].push 
                            dist:   gapDiff
                            gap:    gapDist
                            a:      'gap'
                            val:    gap
                            item:   other
                            id:     'gap'+other.id()
                            span:   [
                                ibox[if neg == 1 then ic[xy] else oc[xy]], 
                                obox[if neg == 1 then oc[xy] else ic[xy]], 
                                (obox[oo[xy]]+ibox[oo[xy]])/2
                            ]
        for xy in 'xy'
            
            closest[xy].sort (a,b) -> Math.abs(a.dist) - Math.abs(b.dist)
            
        closest
        
    # 0000000    00000000  000      000000000   0000000   
    # 000   000  000       000         000     000   000  
    # 000   000  0000000   000         000     000000000  
    # 000   000  000       000         000     000   000  
    # 0000000    00000000  0000000     000     000   000  
    
    itemsDelta: (items, oldDelta) -> 
        
        @svg.clear()
        
        delta = pos oldDelta
        
        if @snapGrid or @snapCenter or @snapBorder or @snapGaps
                                    
            xyClosest = @calcClosest items
            for xy,closest of xyClosest
                                                                    
                if valid closest
                    
                    winner = first closest
                                        
                    if @winner[xy]? and @winner[xy].id != winner.id
                        oldKeep = @snapKeep[xy]
                        @snapKeep[xy] = delta[xy]-winner.dist
                        delta[xy] = winner.dist + oldKeep
                    else 
                        if @snapKeep[xy]
                            @snapKeep[xy] += delta[xy]
                            delta[xy] = 0
                        else
                            @snapKeep[xy] = delta[xy]-winner.dist
                            delta[xy] = winner.dist
                    
                    @winner[xy] = winner
                    
                    if @visible then @drawClosest xy, closest
                    
                else
                    
                    delta[xy] += @snapKeep[xy]
                    @snapKeep[xy] = 0
                    @winner[xy] = null
                    
        else
            @snapKeep = pos 0,0
            @winner = x:null, y:null
            
        delta

    #  0000000   0000000   000       0000000  
    # 000       000   000  000      000       
    # 000       000000000  000      000       
    # 000       000   000  000      000       
    #  0000000  000   000  0000000   0000000  
    
    calcClosest: (items) ->
        
        if @snapDeep
            thisItems = []
            for item in items
                thisItems = thisItems.concat @stage.treeItems item:item
        else
            thisItems = items
                
        itemBoxes = thisItems.map (item) => [item, moveBox @trans.getRect(item), @snapKeep]

        if @snapDeep
            otherItems = @stage.treeItems pickable:true
        else
            otherItems = @stage.pickableItems()
        
        otherItems = otherItems.filter (o) -> o not in thisItems and empty _.intersection o.parents(), thisItems
            
        otherBoxes = otherItems.map (item) => [item, @trans.getRect item]
            
        closest = x:[], y:[]
        combis  = @combinations()
        
        gaps = @calcGaps otherBoxes
        
        for xy in 'xy'
            
            for [other,obox] in otherBoxes
                for [item,ibox] in itemBoxes
                    
                    for [a,b] in combis[xy]
                    
                        dist = obox[a] - ibox[b]
                        dist = Math.round(dist*100)/100
                        
                        if Math.abs(dist) <= @snapDist
                            
                            closest[xy].push 
                                dist:   dist
                                a:      a
                                val:    obox[a]
                                item:   other
                                id:     a+other.id()

                    continue if not @snapGaps or empty gaps[xy]

                    oo = x:'cy', y:'cx'
                    os = x:'h',  y:'w'
                    
                    continue if Math.abs(obox[oo[xy]]-ibox[oo[xy]]) > (obox[os[xy]]+ibox[os[xy]])/2
                    
                    ic = x:'x2', y:'y2'
                    oc = x:'x',  y:'y'
                    
                    if obox[oc[xy]] > ibox[ic[xy]]
                        dist = obox[oc[xy]] - ibox[ic[xy]]
                        neg = 1
                    else if ibox[oc[xy]] > obox[ic[xy]]
                        dist = ibox[oc[xy]] - obox[ic[xy]]
                        neg = -1
                    else
                        continue
                        
                    for gapDist,gap of gaps[xy]
                        
                        gapDiff = dist - gapDist
                        gapDiff *= neg
                        
                        if Math.abs(gapDiff) <= @snapDist
                            closest[xy].push 
                                dist:   gapDiff
                                gap:    gapDist
                                a:      'gap'
                                val:    gap
                                item:   other
                                id:     'gap'+other.id()
                                span:   [
                                    ibox[if neg == 1 then ic[xy] else oc[xy]], 
                                    obox[if neg == 1 then oc[xy] else ic[xy]], 
                                    (obox[oo[xy]]+ibox[oo[xy]])/2
                                ]
        for xy in 'xy'
            
            closest[xy].sort (a,b) -> Math.abs(a.dist) - Math.abs(b.dist)
            
        closest

    #  0000000    0000000   00000000    0000000  
    # 000        000   000  000   000  000       
    # 000  0000  000000000  00000000   0000000   
    # 000   000  000   000  000             000  
    #  0000000   000   000  000        0000000   
    
    calcGaps: (otherBoxes) ->
        
        gaps = x:{}, y:{}
        
        return gaps if not @snapGaps or otherBoxes.length < 2
        
        ic = x:'x2', y:'y2'
        nc = x:'x',  y:'y'
        oc = x:'cy', y:'cx'
        os = x:'h',  y:'w'

        for xy in 'xy'
            
            skippedBoxes = _.clone otherBoxes
            while valid skippedBoxes
                boxes = _.clone skippedBoxes
                skippedBoxes = []
                boxes.sort (a,b) -> a[1][xy] - b[1][xy]
                [item, ibox] = boxes.shift()
                while valid boxes
                    [next, nbox] = boxes.shift()
                    if (nbox[nc[xy]] > ibox[ic[xy]]) and Math.abs(nbox[oc[xy]]-ibox[oc[xy]])<=(ibox[os[xy]]+nbox[os[xy]])/2
                        dist = nbox[nc[xy]] - ibox[ic[xy]]
                        dist = Math.round(dist*100)/100
                        gaps[xy][dist] ?= spans:[], gap:dist
                        gap = gaps[xy][dist]
                        gap.spans.push [ibox[ic[xy]], nbox[nc[xy]], (ibox[oc[xy]]+nbox[oc[xy]])/2]
                        [item, ibox] = [next, nbox]
                    else
                        skippedBoxes.push [next, nbox]
        gaps
        
    # 0000000    00000000    0000000   000   000  
    # 000   000  000   000  000   000  000 0 000  
    # 000   000  0000000    000000000  000000000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000  00     00  
    
    drawClosest: (xy, closest) ->
        
        while valid(closest) and Math.abs(first(closest).dist - @winner[xy].dist) < 0.01
            
            close = closest.shift()
            size  = 6/@stage.zoom
            
            if close.a == 'gap'
                
                oo = x:'y', y:'x'
                gap = close.val
                
                for span in gap.spans.concat [close.span]
                    
                    if xy == 'x'
                        x1 = span[0]
                        y1 = span[2]
                        x2 = span[1]
                        y2 = span[2]
                    else
                        x1 = span[2]
                        y1 = span[0]
                        x2 = span[2]
                        y2 = span[1]
                        
                    l = @svg.line x1, y1, x2, y2
                    l.style 'stroke-width', 1/@stage.zoom
                    l.addClass 'snap-gap'
                    r = @svg.rect size, size
                    r.addClass 'snap-gap'
                    @trans.center r, pos x1, y1
                    r = @svg.rect size, size
                    r.addClass 'snap-gap'
                    @trans.center r, pos x2, y2
            else
                
                val = close.val
                max = Number.MAX_SAFE_INTEGER
                min = Number.MIN_SAFE_INTEGER
                if xy == 'x'
                    l = @svg.line val, min, val, max
                else
                    l = @svg.line min, val, max, val
                l.style 'stroke-width', 1/@stage.zoom
                center = @trans.center close.item
                if close.a in ['cx', 'cy']
                    c = @svg.circle()
                    c.size size, size
                    l.addClass 'snap-center'
                    c.addClass 'snap-center'
                    @trans.center c, center
                else
                    r = @svg.rect size, size
                    switch close.a
                        when 'x', 'x2' then center.x = val
                        when 'y', 'y2' then center.y = val
                    @trans.center r, center
        
    #  0000000   0000000   00     00  0000000    000   0000000  
    # 000       000   000  000   000  000   000  000  000       
    # 000       000   000  000000000  0000000    000  0000000   
    # 000       000   000  000 0 000  000   000  000       000  
    #  0000000   0000000   000   000  0000000    000  0000000   
    
    combinations: ->
        
        attribs = x:[], y:[]
        if @snapCenter
            attribs.x.push 'cx'
            attribs.y.push 'cy'
        if @snapBorder
            attribs.x.push 'x'
            attribs.x.push 'x2'
            attribs.y.push 'y'
            attribs.y.push 'y2'
        
        combis = x:[], y:[]
        for orientation,attrib of attribs
            for a in attrib
                for b in attrib
                    combis[orientation].push [a,b]
        combis        
        
    onSnapCenter: =>
        
        @snapCenter = @button('center').toggle
        prefs.set 'snap:center', @snapCenter

    onSnapBorder: =>
        
        @snapBorder = @button('border').toggle
        prefs.set 'snap:border', @snapBorder

    onSnapDeep: =>
        
        @snapDeep = @button('deep').toggle
        prefs.set 'snap:deep', @snapDeep

    onSnapGaps: =>
        
        @snapGaps = @button('gaps').toggle
        prefs.set 'snap:gaps', @snapGaps
        
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

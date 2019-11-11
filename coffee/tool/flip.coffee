###
00000000  000      000  00000000   
000       000      000  000   000  
000000    000      000  00000000   
000       000      000  000        
000       0000000  000  000        
###

{ empty, first, kpos } = require 'kxk'

{ itemIDs, boxPos, boxCenter, itemMatrix } = require '../utils'

Tool = require './tool'

class Flip extends Tool

    constructor: (kali, cfg) ->

        super kali, cfg
        
        @trans = @kali.trans
        
        @initTitle()
        @initButtons [
            icon: 'flip-horizontal'
            name: 'horizontal'
            action: => @onFlip 'horizontal'
        ,
            icon: 'flip-vertical'
            name: 'vertical'
            action: => @onFlip 'vertical'
        ]
            
    onFlip: (orientation) =>
                
        items = @stage.selectedLeafItems()
                
        return if empty items
        
        @stage.do "flip" + itemIDs items
        
        for item in items
            @flipItem item, orientation
            
        for item in @stage.selectedLeafItems(type:'g')
            @flipGroup item, orientation
                    
        @stage.shapes.edit?.update()
            
        @stage.done()
       
    flipGroup: (group, orientation) ->
        
        switch orientation
            when 'horizontal' then scale = kpos -1, +1
            when 'vertical'   then scale = kpos +1, -1

        gb = first(group.children()).bbox().transform first(group.children()).transform().matrix
        for item in group.children()
            gb = gb.merge item.bbox().transform item.transform().matrix
         
        for item in group.children()
            ib = item.bbox().transform item.transform().matrix
            oldCenter = boxCenter ib
            newCenter = new SVG.Point oldCenter
            newCenter = kpos newCenter.transform new SVG.Matrix().around gb.cx, gb.cy, new SVG.Matrix().scale scale.x, scale.y
            delta = oldCenter.to newCenter
            item.transform x:item.transform().x+delta.x, y:item.transform().y+delta.y
            
    flipItem: (item, orientation) ->
        
        if item.type not in ['path', 'polygon', 'line', 'polyline']
            return 
        
        bb = item.bbox()
        points = item.array().valueOf()
        
        o = if item.type == 'path' then 1 else 0
        
        for point in points
            
            switch orientation
                
                when 'horizontal'
                    
                    for i in [o...point.length] by 2
                        point[i] = bb.x2 - (point[i] - bb.x)
                    
                when 'vertical'
                    
                    for i in [o+1...point.length] by 2
                        point[i] = bb.y2 - (point[i] - bb.y)
                
        item.plot points
        
module.exports = Flip

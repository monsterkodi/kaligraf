###
 0000000   000      000   0000000   000   000
000   000  000      000  000        0000  000
000000000  000      000  000  0000  000 0 000
000   000  000      000  000   000  000  0000
000   000  0000000  000   0000000   000   000
###

{ post, first, pos, log, $, _ } = require 'kxk'

{ itemIDs } = require '../utils'

Tool = require './tool'

class Align extends Tool

    constructor: (kali, cfg) ->

        super kali, cfg
        
        @initTitle()
        @initButtons [
            tiny: 'align-left'
            name: 'left'
            action: => @onAlign 'left'
        ,
            tiny: 'align-center'
            name: 'center'
            action: => @onAlign 'center'
        ,
            tiny: 'align-right'
            name: 'right'
            action: => @onAlign 'right'
        ]
        @initButtons [
            tiny: 'align-top'
            name: 'top'
            action: => @onAlign 'top'
        ,
            tiny: 'align-mid'
            name: 'mid'
            action: => @onAlign 'mid'
        ,
            tiny: 'align-bot'
            name: 'bot'
            action: => @onAlign 'bot'
        ]
        
        @trans = @kali.trans
            
    #  0000000   000      000   0000000   000   000  
    # 000   000  000      000  000        0000  000  
    # 000000000  000      000  000  0000  000 0 000  
    # 000   000  000      000  000   000  000  0000  
    # 000   000  0000000  000   0000000   000   000  
    
    onAlign: (side) =>
        
        if @stage.shapes.edit?.dotsel.numDots()
            @stage.shapes.edit?.dotsel.align side
            return
        
        switch side
            when 'center', 'mid' then sum = 0 
            when 'left', 'top'  then avg = Number.MAX_SAFE_INTEGER
            when 'bot', 'right' then avg = Number.MIN_SAFE_INTEGER
                
        items = @stage.selectedItems()
        
        if items.length == 1 and first(items).type == 'g'
            items = first(items).children()
        
        return if items.length < 2
        
        @stage.do "align" + itemIDs items
        
        for item in items
            rect = @trans.getRect item
            switch side
                when 'center' then sum += rect.cx
                when 'mid'    then sum += rect.cy
                when 'left'   then avg = Math.min avg, rect.x
                when 'top'    then avg = Math.min avg, rect.y
                when 'right'  then avg = Math.max avg, rect.x2
                when 'bot'    then avg = Math.max avg, rect.y2
        
        switch side
            when 'center', 'mid'
                avg = sum / items.length
        
        for item in items
            rect = @trans.getRect item
            oldCenter = @trans.center item
            newCenter = pos oldCenter
            
            switch side
                when 'left'   then newCenter.x = avg + rect.width/2
                when 'right'  then newCenter.x = avg - rect.width/2
                when 'center' then newCenter.x = avg 
                when 'top'    then newCenter.y = avg + rect.height/2  
                when 'bot'    then newCenter.y = avg - rect.height/2
                when 'mid'    then newCenter.y = avg
                               
            @trans.center item, newCenter
            
        @stage.selection.update()
        @stage.resizer.update()
        
        @stage.done()
        
        post.emit 'align', side
        
module.exports = Align

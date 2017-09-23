
#  0000000   000      000   0000000   000   000
# 000   000  000      000  000        0000  000
# 000000000  000      000  000  0000  000 0 000
# 000   000  000      000  000   000  000  0000
# 000   000  0000000  000   0000000   000   000

{ post, first, pos, log, $, _ } = require 'kxk'

Tool = require './tool'

class Align extends Tool

    constructor: (@kali, cfg) ->

        super @kali, cfg
        
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
            log "align dots #{side}"
            @stage.shapes.edit?.dotsel.align side
            return
        
        sum = 0
        items = @stage.selectedItems()
        
        if items.length == 1 and first(items).type == 'g'
            items = first(items).children()
        
        return if items.length < 2
        
        for item in items
            bbox = @trans.getRect item
            switch side
                when 'left'   then sum += bbox.x
                when 'right'  then sum += bbox.x2
                when 'center' then sum += bbox.cx
                when 'top'    then sum += bbox.y
                when 'bot'    then sum += bbox.y2
                when 'mid'    then sum += bbox.cy
                    
        avg = sum / items.length
        
        for item in items
            oldPos = @trans.pos item
            newPos = pos oldPos
            bbox = @trans.getRect item
            switch side
                when 'left'   then newPos.x = avg
                when 'right'  then newPos.x = avg - bbox.width
                when 'center' then newPos.x = avg - bbox.width/2
                when 'top'    then newPos.y = avg
                when 'bot'    then newPos.y = avg - bbox.height
                when 'mid'    then newPos.y = avg - bbox.height/2
                              
            @trans.pos item, newPos
            
        @stage.selection.update()
        @stage.resizer.update()
        
module.exports = Align

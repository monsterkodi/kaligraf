
#  0000000   000      000   0000000   000   000
# 000   000  000      000  000        0000  000
# 000000000  000      000  000  0000  000 0 000
# 000   000  000      000  000   000  000  0000
# 000   000  0000000  000   0000000   000   000

{ post, pos, log, $, _ } = require 'kxk'

Tool = require './tool'

class Align extends Tool

    constructor: (@kali, cfg) ->

        super @kali, cfg
        
        @initTitle 'Align'
        @initButtons [
            text: 'L'
            action: => @onAlign 'left'
        ,
            text: 'C'
            action: => @onAlign 'center'
        ,
            text: 'R'
            action: => @onAlign 'right'
        ]
        @initButtons [
            text: 'T'
            action: => @onAlign 'top'
        ,
            text: 'M'
            action: => @onAlign 'mid'
        ,
            text: 'B'
            action: => @onAlign 'bot'
        ]
        
        @stage = @kali.stage
        @trans = @kali.trans
        
        post.on 'align', @onAlign
        post.on 'space', @onSpace

    #  0000000  00000000    0000000    0000000  00000000  
    # 000       000   000  000   000  000       000       
    # 0000000   00000000   000000000  000       0000000   
    #      000  000        000   000  000       000       
    # 0000000   000        000   000   0000000  00000000  
    
    onSpace: (direction) =>
        
        items = @stage.selectedItems()
        
        return if items.length < 3
        
        switch direction
            when 'horizontal' then items.sort (a,b) => @trans.center(a).x - @trans.center(b).x
            when 'vertical'   then items.sort (a,b) => @trans.center(a).y - @trans.center(b).y
              
        sum = 0
        for i in [1...items.length]
            a = items[i-1]
            b = items[i]
            ra = @trans.getRect a
            rb = @trans.getRect b
            switch direction
                when 'horizontal' then sum += rb.x - ra.x2
                when 'vertical'   then sum += rb.y - ra.y2
                
        avg = sum/(items.length-1)
        
        for i in [1...items.length]
            a = items[i-1]
            b = items[i]
            ra = @trans.getRect a
            newPos = @trans.pos b
            switch direction
                when 'horizontal' then newPos.x = ra.x2 + avg
                when 'vertical'   then newPos.y = ra.y2 + avg
            @trans.pos b, newPos
            
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
        
module.exports = Align

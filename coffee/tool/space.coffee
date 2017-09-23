
#  0000000  00000000    0000000    0000000  00000000  
# 000       000   000  000   000  000       000       
# 0000000   00000000   000000000  000       0000000   
#      000  000        000   000  000       000       
# 0000000   000        000   000   0000000  00000000  

{ post, pos, log, $, _ } = require 'kxk'

Tool = require './tool'

class Space extends Tool

    constructor: (@kali, cfg) ->

        super @kali, cfg
        
        @initTitle()
        @initButtons [
            icon:   'space-horizontal'
            name:   'horizontal'
            action: => @onSpace 'horizontal'
        ,
            icon:   'space-vertical'
            name:   'vertical'
            action: => @onSpace 'vertical'
        ]
        
        @trans = @kali.trans

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

        @stage.selection.update()
        @stage.resizer.update()
            
module.exports = Space

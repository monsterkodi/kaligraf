
#  0000000   00000000   0000000    00000000  00000000 
# 000   000  000   000  000   000  000       000   000
# 000   000  0000000    000   000  0000000   0000000  
# 000   000  000   000  000   000  000       000   000
#  0000000   000   000  0000000    00000000  000   000

{ post, pos, log, $, _ } = require 'kxk'

Tool = require './tool'

class Order extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @stage.order = Order.order    

        @initTitle()
        @initButtons [
            text: 'F'
            name: 'front'
            action: => @stage.order 'front'
        ,
            text: 'f'
            name: 'forward'
            action: => @stage.order 'forward'
        ]
        @initButtons [
            text: 'B'
            name: 'back'
            action: => @stage.order 'back'
        ,
            text: 'b'
            name: 'backward'
            action: => @stage.order 'backward'
        ]

    #  0000000  000000000   0000000    0000000   00000000  
    # 000          000     000   000  000        000       
    # 0000000      000     000000000  000  0000  0000000   
    #      000     000     000   000  000   000  000       
    # 0000000      000     000   000   0000000   00000000  
    
    @order: (order) ->

        @do()
        for item in @selectedItems()
            item[order]()
        @done()
        
module.exports = Order

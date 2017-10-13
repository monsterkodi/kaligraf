
#  0000000  000   000   0000000   00000000   
# 000       0000  000  000   000  000   000  
# 0000000   000 0 000  000000000  00000000   
#      000  000  0000  000   000  000        
# 0000000   000   000  000   000  000        

{ elem, prefs, empty, clamp, post, log, _ } = require 'kxk'

{ itemIDs, growBox, boxOffset, bboxForItems, scaleBox, moveBox, setBox } = require '../utils'

Tool = require './tool'

class Snap extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @selection = @stage.selection
        
        @visible  = prefs.get 'snap:visible', false
        @snapGrid = prefs.get 'snap:grid',    false
        @snapItem = prefs.get 'snap:item',    false
        
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

    # 000  000000000  00000000  00     00   0000000  0000000    00000000  000      000000000   0000000   
    # 000     000     000       000   000  000       000   000  000       000         000     000   000  
    # 000     000     0000000   000000000  0000000   000   000  0000000   000         000     000000000  
    # 000     000     000       000 0 000       000  000   000  000       000         000     000   000  
    # 000     000     00000000  000   000  0000000   0000000    00000000  0000000     000     000   000  
    
    itemsDelta: (items, delta) -> 
        if @snapGrid or @snapItem
            log 'itemsDelta', delta, bboxForItems items
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

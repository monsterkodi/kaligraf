
#  0000000  000   000   0000000   000   000  
# 000       000   000  000   000  000 0 000  
# 0000000   000000000  000   000  000000000  
#      000  000   000  000   000  000   000  
# 0000000   000   000   0000000   00     00  

{ post, prefs, log, _ } = require 'kxk'

{ contrastColor } = require '../utils'

Tool = require './tool'

class Show extends Tool
        
    constructor: (@kali, cfg) ->
        
        super @kali, cfg
        
        @trans     = @kali.trans
        @selection = @stage.selection
        @stage.ids = Show.ids.bind @stage
        
        @initTitle()
                
        groups = prefs.get 'stage:groups', false
        
        @initButtons [
            text:   'Groups'
            name:   'groups'
            action: @toggleGroups
            toggle: groups
        ]
        @initButtons [
            text:   'IDs'
            name:   'ids'
            action: @stage.ids
            toggle: prefs.get 'stage:ids', false
        ]
        
        post.on 'stage', @onStage
        post.on 'group', (action) => 
            switch action
                when 'group'   then @updateGroups()
                when 'ungroup' then @refreshGroups()
        post.on 'resizer', @updateGroups
        post.on 'align',   @updateGroups
        post.on 'undo',    @refreshGroups
        
        @showGroups groups
        
    execute: -> 

    #  0000000  000000000   0000000    0000000   00000000    
    # 000          000     000   000  000        000         
    # 0000000      000     000000000  000  0000  0000000     
    #      000     000     000   000  000   000  000         
    # 0000000      000     000   000   0000000   00000000    
            
    @ids: -> 
    
        ids = prefs.get 'stage:ids', false
        ids = !ids
        prefs.set 'stage:ids', ids
        
        @selection.showIDs ids
        
    onStage: (action) => 
    
        if @grps?
    
            switch action 
                when 'load'      then @refreshGroups()
                when 'moveItems' then @updateGroups()
                when 'viewbox' 
                    @grps.viewbox @stage.svg.viewbox()
                    @grps.style 'stroke-width': 1/@stage.zoom
                when 'color'
                    @grps.style stroke: contrastColor @stage.color
        
    #  0000000   00000000    0000000   000   000  00000000    0000000  
    # 000        000   000  000   000  000   000  000   000  000       
    # 000  0000  0000000    000   000  000   000  00000000   0000000   
    # 000   000  000   000  000   000  000   000  000             000  
    #  0000000   000   000   0000000    0000000   000        0000000   
    
    toggleGroups: =>
    
        @showGroups !prefs.get 'stage:groups', false

    refreshGroups: =>
        
        @clearGroups()
        @updateGroups()
        
    #  0000000  000   000   0000000   000   000  
    # 000       000   000  000   000  000 0 000  
    # 0000000   000000000  000   000  000000000  
    #      000  000   000  000   000  000   000  
    # 0000000   000   000   0000000   00     00  
    
    showGroups: (show=true) ->

        prefs.set 'stage:groups', show
                
        if show
            if not @grps?
                @grps = SVG(@selection.element).size '100%', '100%'
                @grps.viewbox @stage.svg.viewbox()
                @grps.addClass 'groupRects'
                @grps.style 
                    stroke: contrastColor @stage.color
                    'stroke-width': 1/@stage.zoom
                @selection.element.insertBefore @grps.node, @selection.rectsBlack.node.nextSibling
            @grps.clear()
            @updateGroups()
        else
            @clearGroups()
            @grps?.remove()
            delete @grps

    #  0000000  000      00000000   0000000   00000000   
    # 000       000      000       000   000  000   000  
    # 000       000      0000000   000000000  0000000    
    # 000       000      000       000   000  000   000  
    #  0000000  0000000  00000000  000   000  000   000  
    
    clearGroups: ->
            
        if @grps
            for group in @stage.groups()
                group.forget 'groupRect'
            @grps.clear()
                    
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    updateGroups: =>

        if @grps

            @grps.viewbox @stage.svg.viewbox()
            @grps.style 'stroke-width', 1/@stage.zoom
        
            for group in @stage.groups()
                @updateGroup group
            
    updateGroup: (group) ->
        
        if @grps
            
            o = 2/@stage.zoom
            
            box = group.bbox()
            
            if not rect = group.remember 'groupRect'    
                rect = @grps.rect box.width-2*o, box.height-2*o
                rect.addClass  'groupRect'
                group.remember 'groupRect', rect
            else    
                rect.attr width:box.width-2*o, height:box.height-2*o
                
            rect.attr x:box.x+o, y:box.y+o
            @trans.follow rect, group
    
module.exports = Show

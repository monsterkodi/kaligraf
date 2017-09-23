
#  0000000  000   000   0000000   000   000  
# 000       000   000  000   000  000 0 000  
# 0000000   000000000  000   000  000000000  
#      000  000   000  000   000  000   000  
# 0000000   000   000   0000000   00     00  

{ post, prefs, log, _ } = require 'kxk'

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
                when 'group' then @updateGroups()
                when 'ungroup' then @refreshGroups()
        
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
        
    onStage: (action, box) => 
        
        switch action 
            when 'viewbox' then @grps?.viewbox box
            when 'load'    then @refreshGroups()
        
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
        
    showGroups: (show=true) ->

        prefs.set 'stage:groups', show
        log 'showGroups', show
                
        if show
            if not @grps?
                @grps = SVG(@selection.element).size '100%', '100%'
                @grps.viewbox @stage.svg.viewbox()
                @grps.addClass 'groupRects'
                @selection.element.insertBefore @grps.node, @selection.rectsBlack.node.nextSibling
            @grps.clear()
            @updateGroups()
        else
            @clearGroups()
            @grps?.remove()
            delete @grps

    clearGroups: ->
            
        if @grps
            for group in @stage.groups()
                group.forget 'groupRect'
            @grps.clear()
                    
    updateGroups: ->

        if @grps
            @grps.viewbox @stage.svg.viewbox()
            @grps.style 'stroke-width', 1/@stage.zoom
        
            for group in @stage.groups()
                @updateGroup group
            
    updateGroup: (group) ->
        
        if @grps
            
            box = group.bbox()
            
            if not rect = group.remember 'groupRect'    
                rect = @grps.rect 0,0
                rect.addClass 'groupRect'
                group.remember 'groupRect', rect
                
            rect.attr x:box.x, y:box.y
            rect.transform group.transform()
            @trans.width  rect, box.width
            @trans.height rect, box.height
    
module.exports = Show

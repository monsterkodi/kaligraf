###
000000000   0000000   0000000  
   000     000   000  000   000
   000     000000000  0000000  
   000     000   000  000   000
   000     000   000  0000000  
###

{ elem, post, slash, fs, error, log, _ } = require 'kxk'

Tooltip = require './tooltip'

class Tab
    
    constructor: (@tabs) ->
        
        @info = file: null
        @div = elem class: 'tab', text: 'untitled'
        @tabs.div.appendChild @div

    tabData: -> @info
        
    #  0000000   0000000   000   000  00000000
    # 000       000   000  000   000  000     
    # 0000000   000000000   000 000   0000000 
    #      000  000   000     000     000     
    # 0000000   000   000      0      00000000
    
    saveChanges: -> log 'tab.saveChanges'
            
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: (info) ->
            
        log 'tab.update', info
        oldFile = @info?.file
        
        @info = _.clone info
                                
        @div.innerHTML = ''
        @div.classList.toggle 'dirty', @dirty()
                
        @div.appendChild elem 'span', class:'dot', text:'●'
        
        name = elem 'span', class:'name', html:slash.base @file()
        @div.appendChild name

        if @info.file?
            @tooltip = new Tooltip elem:name, html:slash.tilde(@file()), x:0
            
        @div.appendChild elem 'span', class:'dot', text:'●' if @dirty()
        @

    file:  -> @info?.file ? 'untitled' 
    index: -> @tabs.tabs.indexOf @
    prev:  -> @tabs.tab @index()-1 if @index() > 0
    next:  -> @tabs.tab @index()+1 if @index() < @tabs.numTabs()-1
    nextOrPrev: -> @next() ? @prev()
    
    dirty: -> 
        return true if @state? 
        return true if @info?.dirty == true
        false
        
    close: ->
        
        @div.remove()
        @tooltip.del()
        post.emit 'tabClosed', @info.file ? 'untitled'
    
    revert: -> 
        delete @info.dirty
        delete @foreign
        delete @state
        @update @info

    #  0000000    0000000  000000000  000  000   000   0000000   000000000  00000000  
    # 000   000  000          000     000  000   000  000   000     000     000       
    # 000000000  000          000     000   000 000   000000000     000     0000000   
    # 000   000  000          000     000     000     000   000     000     000       
    # 000   000   0000000     000     000      0      000   000     000     00000000  
    
    activate: ->
        
        activeTab = @tabs.activeTab()

        if activeTab? and activeTab.dirty()
            activeTab.storeState()
        
        @setActive()
        
        if @state?
            @restoreState()
        else
            log 'tab activate', @info
            post.emit 'stage', 'loadFile', @info
            
        @tabs.stash()

    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    isActive: -> @div.classList.contains 'active'
    
    setActive: -> 
        if not @isActive()
            @tabs.activeTab()?.clearActive()
            @div.classList.add 'active'
            
    clearActive: -> @div.classList.remove 'active'
        
module.exports = Tab

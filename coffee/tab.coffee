###
000000000   0000000   0000000  
   000     000   000  000   000
   000     000000000  0000000  
   000     000   000  000   000
   000     000   000  0000000  
###

{ post, tooltip, elem, slash, fs, error, log, _ } = require 'kxk'

class Tab
    
    constructor: (@tabs) ->
        
        @info = file: null
        @div = elem class: 'tab', text: 'untitled'
        @tabs.div.appendChild @div

    tabData: -> @info
        
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: (info) ->
            
        oldFile = @info?.file
        
        @info = _.clone info
        delete @info.dontActivate
                                
        @div.innerHTML = ''
        @div.classList.toggle 'dirty', @dirty()
                
        @div.appendChild elem 'span', class:'dot', text:info.dir and '🖿' or '●'
        
        name = elem 'span', class:'name', html:slash.base @file()
        @div.appendChild name

        if @info.file?
            @tooltip = new tooltip elem:name, html:slash.tilde(@file()), x:0
            
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
        
    setDirty: (dirty) ->
        if dirty
            @info.dirty = dirty
        else
            delete @info.dirty
        @div.classList.toggle 'dirty', @dirty()
        
    close: ->
        
        @div.remove()
        @tooltip?.del()
        post.emit 'tabClosed', @info.file ? 'untitled'
    
    revert: -> 
        delete @info.dirty
        delete @state
        @update @info

    #  0000000    0000000  000000000  000  000   000   0000000   000000000  00000000  
    # 000   000  000          000     000  000   000  000   000     000     000       
    # 000000000  000          000     000   000 000   000000000     000     0000000   
    # 000   000  000          000     000     000     000   000     000     000       
    # 000   000   0000000     000     000      0      000   000     000     00000000  
    
    activate: ->
        
        activeTab = @tabs.activeTab()

        @setActive()
        
        if @state?
            @restoreState()
        else
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

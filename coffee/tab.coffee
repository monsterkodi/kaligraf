###
000000000   0000000   0000000  
   000     000   000  000   000
   000     000000000  0000000  
   000     000   000  000   000
   000     000   000  0000000  
###

{ elem, post, atomic, slash, fs, error, log, _ } = require 'kxk'

Tooltip = require './tooltip'

class Tab
    
    constructor: (@tabs) ->
        
        @info = file: null
        @div = elem class: 'tab', text: 'untitled'
        @tabs.div.appendChild @div

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
            
        oldFile = @info?.file
        
        @info = _.clone info
                                
        @div.innerHTML = ''
        @div.classList.toggle 'dirty', @dirty()
                
        sep = '●'
        sep = '■' if window.editor.newlineCharacters == '\r\n'
        @div.appendChild elem 'span', class:'dot', text:sep
        
        diss = syntax.dissForTextAndSyntax slash.basename(@file()), 'ko' #, join: true 
        name = elem 'span', class:'name', html:render.line(diss, charWidth:0)
        @div.appendChild name

        if @info.file?
            diss = syntax.dissForTextAndSyntax slash.tilde(@file()), 'ko' #, join: true 
            html = render.line(diss, charWidth:0)
            @tooltip = new Tooltip elem:name, html:html, x:0
            
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
        @tabs.update()

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
            window.loadFile @info.file, dontSave:true
            
        if @foreign?.length
            for changes in @foreign
                window.editor.do.foreignChanges changes
            delete @foreign
            
        @tabs.update()

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

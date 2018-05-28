###
000000000   0000000   0000000     0000000
   000     000   000  000   000  000     
   000     000000000  0000000    0000000 
   000     000   000  000   000       000
   000     000   000  0000000    0000000 
###

{ post, elem, drag, prefs, slash, error, log, _ } = require 'kxk'

Tab = require './tab'

class Tabs
    
    constructor: (view) ->
        
        @tabs = []
        @div = elem class: 'tabs'
        view.appendChild @div
        
        @div.addEventListener 'click', @onClick
        
        @drag = new drag
            target: @div
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop

        post.on 'stage', @onStage
        post.on 'undo',  @onUndo
        
    onStage: (action, info) =>
        
        switch action 
            when 'load'
                log 'tabs.onStage', action, info.file
                @addTab file:info.file
            # when 'save', 'clear'
                # log 'tabs.onStage', action, info
        
    onUndo: (info) =>
        # log 'tabs.onUndo', info
        @activeTab()?.setDirty info.dirty
            
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (event) =>
        
        if tab = @tab event.target
            if event.target.classList.contains 'dot'
                @closeTab tab
            else
                tab.activate()
        true

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (d, e) => 
        
        if e.button == 2
            @closeTab @tab e.target
            return 'skip'
            
        @dragTab = @tab e.target
        @dragDiv = @dragTab.div.cloneNode true
        @dragTab.div.style.opacity = '0'
        br = @dragTab.div.getBoundingClientRect()
        @dragDiv.style.position = 'absolute'
        @dragDiv.style.top  = "#{br.top}px"
        @dragDiv.style.left = "#{br.left}px"
        @dragDiv.style.width = "#{br.width-12}px"
        @dragDiv.style.height = "#{br.height-3}px"
        @dragDiv.style.flex = 'unset'
        @dragDiv.style.pointerEvents = 'none'
        document.body.appendChild @dragDiv

    onDragMove: (d,e) =>
        
        @dragDiv.style.transform = "translateX(#{d.deltaSum.x}px)"
        if tab = @tabAtX d.pos.x
            if tab.index() != @dragTab.index()
                @swap tab, @dragTab
        
    onDragStop: (d,e) =>
        
        @dragTab.div.style.opacity = ''
        @dragDiv.remove()

    # 000000000   0000000   0000000    
    #    000     000   000  000   000  
    #    000     000000000  0000000    
    #    000     000   000  000   000  
    #    000     000   000  0000000    
    
    tab: (id) ->
        
        if _.isNumber  id then return @tabs[id]
        if _.isElement id then return _.find @tabs, (t) -> t.div.contains id
        if _.isString  id then return _.find @tabs, (t) -> t.info.file == id

    activeTab: -> _.find @tabs, (t) -> t.isActive()
    numTabs:   -> @tabs.length
    
    tabAtX: (x) -> 
        
        _.find @tabs, (t) -> 
            br = t.div.getBoundingClientRect()
            br.left <= x <= br.left + br.width
    
    #  0000000  000       0000000    0000000  00000000  
    # 000       000      000   000  000       000       
    # 000       000      000   000  0000000   0000000   
    # 000       000      000   000       000  000       
    #  0000000  0000000   0000000   0000000   00000000  
    
    closeTab: (tab = @activeTab()) ->
        
        return if not tab?
        
        # log 'tabs.closeTab', tab.dirty()
        # if tab.dirty() and tab == @activeTab()
            # post.emit 'stage', 'saveFile'
           
        if @tabs.length > 1
            if tab == @activeTab()
                tab.nextOrPrev()?.activate()
        else
            post.emit 'menuAction', 'Clear'
        tab.close()
        
        _.pull @tabs, tab
        @stash()
        @
  
    closeOtherTabs: -> 
        
        return if not @activeTab()
        keep = _.pullAt @tabs, @activeTab().index()
        while @numTabs()
            # tab = _.last @tabs
            # if tab.dirty()
                # tab.saveChanges()
            @tabs.pop().close()
        @tabs = keep
        @stash()
    
    closeTabs: =>
        
        while @numTabs()
            @tabs.pop().close()
        
    #  0000000   0000000    0000000          000000000   0000000   0000000    
    # 000   000  000   000  000   000           000     000   000  000   000  
    # 000000000  000   000  000   000           000     000000000  0000000    
    # 000   000  000   000  000   000           000     000   000  000   000  
    # 000   000  0000000    0000000             000     000   000  0000000    
    
    addTab: (data) ->
        
        file = data.file
        tab = @tab file
        if not tab
            tab = new Tab @
            tab.update data
            @tabs.push tab
            @stash()
        if not data.dontActivate
            tab.setActive()
        tab

    onNewEmptyTab: => @addTab(file:'untitled').activate()
        
    # 000   000   0000000   000   000  000   0000000    0000000   000000000  00000000  
    # 0000  000  000   000  000   000  000  000        000   000     000     000       
    # 000 0 000  000000000   000 000   000  000  0000  000000000     000     0000000   
    # 000  0000  000   000     000     000  000   000  000   000     000     000       
    # 000   000  000   000      0      000   0000000   000   000     000     00000000  
    
    navigate: (key) ->
        
        index = @activeTab().index()
        index += switch key
            when 'left' then -1
            when 'right' then +1
        index = (@numTabs() + index) % @numTabs()
        @tabs[index].activate()

    swap: (ta, tb) ->
        
        return if not ta? or not tb?
        [ta, tb] = [tb, ta] if ta.index() > tb.index()
        @tabs[ta.index()]   = tb
        @tabs[tb.index()+1] = ta
        @div.insertBefore tb.div, ta.div
        @stash()
    
    move: (key) ->
        
        tab = @activeTab()
        switch key
            when 'left'  then @swap tab, tab.prev() 
            when 'right' then @swap tab, tab.next()

    # 00000000   00000000   0000000  000000000   0000000   00000000   00000000  
    # 000   000  000       000          000     000   000  000   000  000       
    # 0000000    0000000   0000000      000     000   000  0000000    0000000   
    # 000   000  000            000     000     000   000  000   000  000       
    # 000   000  00000000  0000000      000      0000000   000   000  00000000  

    stash: => 
        data = 
            files:  ( t.tabData() for t in @tabs )
            active: @activeTab()?.index() ? 0
        # log 'stash', data
        prefs.set 'tabs', data
    
    restore: =>
        
        active = prefs.get 'tabs:active', 0
        files  = prefs.get 'tabs:files'
        
        # log 'tabs.restore', active, files
        return if _.isEmpty files # happens when first window opens
        
        @closeTabs()
        while files.length
            @addTab files.shift()
        
        @tabs[active].activate()
            
    revertFile: (file) => @tab(file)?.revert()
        
module.exports = Tabs

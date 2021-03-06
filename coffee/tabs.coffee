###
000000000   0000000   0000000     0000000
   000     000   000  000   000  000     
   000     000000000  0000000    0000000 
   000     000   000  000   000       000
   000     000   000  0000000    0000000 
###

{ post, empty, prefs, valid, first, elem, drag, klog, $, _ } = require 'kxk'

Tab = require './tab'

class Tabs
    
    constructor: (titlebar) ->
        
        @tabs = []
        @div = elem class: 'tabs'
        
        titlebar.insertBefore @div, $ ".minimize"
        
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
                @addTab file:info.file
            when 'clear'
                @addTab file:info.file
            when 'save'
                klog 'onStage save', info
                if @activeTab()?.file() == 'untitled'
                    untitledTab = @activeTab()
                @addTab file:info.file
                @closeTab untitledTab if untitledTab
        
    onUndo: (info) =>

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
        
        return 'skip' if not @dragTab
        
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
        
        klog 'closeTab' tab.file()
        
        return if not tab?
                   
        if @tabs.length > 1
            if tab == @activeTab()
                tab.nextOrPrev()?.activate()
            
        tab.close()
        
        _.pull @tabs, tab
        @stash()
        
        if empty @tabs # close the window when last tab was closed
            post.emit 'menuAction', 'Close' 
        
        @
  
    closeOtherTabs: -> 
        
        return if not @activeTab()
        keep = _.pullAt @tabs, @activeTab().index()
        while @numTabs()
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

        prefs.set 'tabs', data
    
    restore: =>
        active = prefs.get 'tabs:active', 0
        files  = prefs.get 'tabs:files'
        
        @closeTabs()
        
        if empty files # happens when first window opens
            recent = prefs.get 'recent', []
            if valid recent
                files = [ file:first(recent) ]
            else
                files = [ file:'untitled' ]
        
        while files.length
            @addTab files.shift()
        
        @tabs[active].activate()
            
    revertFile: (file) => @tab(file)?.revert()
        
module.exports = Tabs

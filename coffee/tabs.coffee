###
000000000   0000000   0000000     0000000
   000     000   000  000   000  000     
   000     000000000  0000000    0000000 
   000     000   000  000   000       000
   000     000   000  0000000    0000000 
###

{ post, elem, drag, slash, error, log, _ } = require 'kxk'

Tab = require './tab'

class Tabs
    
    constructor: (view) ->
        
        @tabs = []
        @div = elem class: 'tabs'
        view.appendChild @div
        
        @div.addEventListener 'click',     @onClick
        
        @tabs.push new Tab @
        @tabs[0].setActive()
        
        @drag = new drag
            target: @div
            onStart: @onDragStart
            onMove:  @onDragMove
            onStop:  @onDragStop
        
        # post.on 'newTabWithFile',   @onNewTabWithFile
        # post.on 'newEmptyTab',      @onNewEmptyTab
#         
        # post.on 'closeTabOrWindow', @onCloseTabOrWindow
        # post.on 'closeOtherTabs',   @onCloseOtherTabs
        # post.on 'closeWindow',      @onCloseWindow
        # post.on 'stash',            @stash
        # post.on 'restore',          @restore
        # post.on 'revertFile',       @revertFile
        # post.on 'sendTabs',         @onSendTabs
        # post.on 'fileLineChanges',  @onFileLineChanges
        # post.on 'fileSaved',        @onFileSaved
        
    onSendTabs: (winID) =>
        
        t = ''
        for tab in @tabs
            t += tab.div.innerHTML
        post.toWin winID, 'winTabs', window.winID, t
        
    onFileSaved: (file, winID) =>
        if winID == window.winID
            error "fileSaved from this window? #{file} #{winID}" 
            return 
        tab = @tab file
        if tab? and tab != @activeTab()
            log "reverting tab because foreign win saved #{file}", tab.info
            tab.revert()
            
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (event) =>
            
        if tab = @tab event.target
            if event.target.classList.contains 'dot'
                @onCloseTabOrWindow tab
            else
                tab.activate()
        true

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (d, e) => 
        
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
        
        if tab.dirty()
            tab.saveChanges()
            
        tab.nextOrPrev().activate()
        tab.close()
        
        _.pull @tabs, tab
        @update()
        @
  
    onCloseWindow: -> window.win.close()
        
    onCloseTabOrWindow: (tab) =>
        if @numTabs() == 1
            window.win.close()
        else
            @closeTab tab

    onCloseOtherTabs: => 
        
        keep = _.pullAt @tabs, @activeTab().index()
        while @numTabs()
            tab = _.last @tabs
            if tab.dirty()
                tab.saveChanges()
            @tabs.pop().close()
        @tabs = keep
        @update()
    
    #  0000000   0000000    0000000          000000000   0000000   0000000    
    # 000   000  000   000  000   000           000     000   000  000   000  
    # 000000000  000   000  000   000           000     000000000  0000000    
    # 000   000  000   000  000   000           000     000   000  000   000  
    # 000   000  0000000    0000000             000     000   000  0000000    
    
    addTab: (file) ->

        tab = new Tab @
        tab.update file:file
        @tabs.push tab
        @update()
        tab

    onNewEmptyTab: =>
        
        @addTab('untitled').activate()
        
    onNewTabWithFile: (file) =>
        
        [file, line, col] = slash.splitFileLine file
        
        if tab = @tab file
            tab.activate()
        else
            @addTab(file).activate()
            
        if line or col
            post.emit 'singleCursorAtPos', [col, line-1]

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
        @update()
    
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

        window.stash.set 'tabs', 
            files:  ( t.file() for t in @tabs )
            active: @activeTab().index()
    
    restore: =>
        
        active = window.stash.get 'tabs:active', 0
        files  = window.stash.get 'tabs:files'
        return if _.isEmpty files # happens when first window opens
        
        @tabs[0].update file: files.shift()
        while files.length
            @addTab files.shift()
        
        @tabs[active].activate()
            
        @update()

    revertFile: (file) => @tab(file)?.revert()
        
    # 000   000  00000000   0000000     0000000   000000000  00000000    
    # 000   000  000   000  000   000  000   000     000     000         
    # 000   000  00000000   000   000  000000000     000     0000000     
    # 000   000  000        000   000  000   000     000     000         
    #  0000000   000        0000000    000   000     000     00000000    
    
    update: ->

        @stash()

        pkg = @tabs[0].info.pkg
        @tabs[0].showPkg()
        for tab in @tabs.slice 1
            if tab.info.pkg == pkg
                tab.hidePkg()
            else
                pkg = tab.info.pkg
                tab.showPkg()
        @
        
module.exports = Tabs

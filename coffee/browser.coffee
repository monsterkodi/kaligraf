###
0000000    00000000    0000000   000   000   0000000  00000000  00000000 
000   000  000   000  000   000  000 0 000  000       000       000   000
0000000    0000000    000   000  000000000  0000000   0000000   0000000  
000   000  000   000  000   000  000   000       000  000       000   000
0000000    000   000   0000000   00     00  0000000   00000000  000   000
###

{ stopEvent, setStyle, keyinfo, drag, elem, post, first, prefs, childp, fs, os, slash, empty, clamp, pos, log, $, _ } = require 'kxk'

{ winTitle, boundingBox } = require './utils'

electron = require 'electron'
dialog   = electron.remote.dialog

class Browser

    constructor: (@kali) ->

        @stage = @kali.stage
        
        @element = elem 'div', class: 'browser fill'
        @element.tabIndex = 100
        @element.addEventListener 'wheel',   @onWheel
        @element.addEventListener 'keydown', @onKeyDown
        
        @scale  = prefs.get 'browser:scale'
        @offset = pos 0,0
        
        buttons = [
            text:   'Open'
            action: @onOpen
        ]
            
        dirs = prefs.get 'browser:dirs', []
        for dir in dirs
            if slash.dirExists dir
                buttons.push
                    text:   slash.basename dir
                    data:   dir: dir
                    action: @onDirButton
            
        @title = winTitle close: @close, class: 'browserTitle', buttons: buttons
        @element.appendChild @title 
        
        @scroll = elem class: 'browserScroll'
        @element.appendChild @scroll
        
        @items = elem class: 'browserItems'
        @scroll.appendChild @items
                
        @kali.insertAboveTools @element
                    
        prefs.set 'browser:open', true
            
        @drag = new drag
            target:  @element
            onStart: @onStart
            onMove:  @onDrag
            onStop:  @onStop
        
        @element.focus()
        post.on 'resize', @onResize
                
    #  0000000   00000000   00000000  000   000  
    # 000   000  000   000  000       0000  000  
    # 000   000  00000000   0000000   000 0 000  
    # 000   000  000        000       000  0000  
    #  0000000   000        00000000  000   000  
    
    onOpen: =>
        
        opts =         
            title:      'Open'
            properties: ['openDirectory']
        
        dialog.showOpenDialog opts, (dirs) => 
            if dir = first dirs
                @browseDir dir
        
    onDirButton: (event) => @browseDir event.target.data.dir
                
    browseDir: (dir) ->
        
        @items.innerHTML = ''
        
        fs.readdir dir, (err, files) =>
            
            return if err? or empty files

            files = files.filter (file) -> slash.extname(file) == '.svg'
            return if empty files 
            
            for file in files
                @addFile slash.join dir, file

            @calcColumns()
            @selectIndex 0
            
            dirs = prefs.get 'browser:dirs', []
            dirs.push(dir) if dir not in dirs
            prefs.set 'browser:dirs', dirs

            @zoomAll()
            
    # 00000000   00000000   0000000  00000000  000   000  000000000  
    # 000   000  000       000       000       0000  000     000     
    # 0000000    0000000   000       0000000   000 0 000     000     
    # 000   000  000       000       000       000  0000     000     
    # 000   000  00000000   0000000  00000000  000   000     000     
    
    browseRecent: (files) ->
            
        for file in files
            if not @addFile file
                @delRecent file

        @calcColumns()
        @setScale @scale
        @fadeCenter 1
        @selectIndex Math.min 1, files.length-1
        @centerSelected()

    delRecent: (file) ->
        
        recent = prefs.get 'recent'
        _.pull recent, file
        prefs.set 'recent', recent
        
    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    del: -> 
        
        @drag.deactivate()
        prefs.set 'browser:open', false
        @element.remove()

    onDelFile: (event) => 
        
        @delItem event.target.parentNode.parentNode
        
    onFinderFile: (event) => 
        
        item = event.target.parentNode.parentNode
        file = item.getAttribute 'file'
        
        stat = fs.statSync file 
        args = [
            '-e', 'tell application "Finder"', 
            '-e', "reveal POSIX file \"#{file}\"",
            '-e', 'activate',
            '-e', 'end tell']
        childp.spawn 'osascript', args
        
    delItem: (item) ->
        
        file = item.getAttribute 'file'

        @delRecent file
        
        if item == @selectedItem() and @items.children.length > 1
            index = clamp 0, @items.children.length-2, elem.childIndex item
            item.remove()
            @selectIndex index
        else
            item.remove()
            
        stopEvent event
                
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    addFile: (file) ->

        try
            svg = fs.readFileSync slash.resolve(file), encoding: 'utf8'
        catch e
            log "error adding file #{file}", e
            return
        
        item = elem 'span', class: 'browserItem'

        text = winTitle class: 'browserItemTitle', close:@onDelFile, buttons: [
            text: slash.base file
            action: @onFinderFile
        ]
        view = elem class: 'browserItemView'
        
        item.setAttribute 'file', file
        item.appendChild text
        item.appendChild view
        
        view.innerHTML = svg
        
        @items.appendChild item
        
        item
                     
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    zoom: (dir) ->
        
        br = @element.getBoundingClientRect()
        @setScale @scale * (1 + dir * 0.5), pos br.width/2, br.height/2
       
    zoomAll: ->
        
        viewBox = boundingBox @scroll
        scaleX = viewBox.w/(@columns*1800)
        scaleY = (viewBox.h-30)/(1200*Math.ceil(@items.children.length/@columns))
        scale = Math.min scaleX, scaleY 
        @setScale scale
        itemBox = boundingBox @items
        @offset.y = (-(viewBox.h-30-itemBox.h)/2)/@scale
        @offset.x = (-(viewBox.w-itemBox.w)/2)/@scale
        @setScale @scale
        @centerSelected()
        
    zoomSelected: ->
        
        viewBox = boundingBox @scroll
        @setScale Math.min(viewBox.w/1650, (viewBox.h-30)/1100)
        @centerSelected()        

    # 00000000   00000000   0000000  000  0000000  00000000    
    # 000   000  000       000       000     000   000         
    # 0000000    0000000   0000000   000    000    0000000     
    # 000   000  000            000  000   000     000         
    # 000   000  00000000  0000000   000  0000000  00000000    
    
    onResize: =>
        
        @calcColumns()
        @fadeCenter 1
        @centerSelected()

    calcColumns: ->
        
        viewBox  = boundingBox @scroll
        aspect   = viewBox.w/viewBox.h
        num      = @items.children.length
        pow      = Math.pow num, 1/(2 * (3/2)/aspect )
        @columns = Math.max 1, Math.ceil pow

        setStyle '.browserItems', 'grid-template-columns', "repeat(#{@columns},1fr)"        
        
    #  0000000   0000000   0000000   000      00000000  
    # 000       000       000   000  000      000       
    # 0000000   000       000000000  000      0000000   
    #      000  000       000   000  000      000       
    # 0000000    0000000  000   000  0000000  00000000  
    
    setScale: (scale, eventPos) ->
        
        if eventPos
            br     = boundingBox @scroll
            oldscl = @scale
            oldoff = @offset.times @scale
            relpos = pos eventPos.x / br.width, eventPos.y / br.height
        
            @scale = clamp 0.05, 50, scale
            
            @offset.y = (oldoff.y + relpos.y * br.height) / oldscl - relpos.y * br.height / @scale
            @offset.x = (oldoff.x + relpos.x * br.width) / oldscl - relpos.x * br.width  / @scale
        else
            @scale = clamp 0.05, 50, scale
        
        prefs.set 'browser:scale', @scale
        
        @items.style.transform = "scale(#{@scale}, #{@scale}) translate(#{-@offset.x}px, #{-@offset.y}px) "
        
    # 000   000  000   000  00000000  00000000  000      
    # 000 0 000  000   000  000       000       000      
    # 000000000  000000000  0000000   0000000   000      
    # 000   000  000   000  000       000       000      
    # 00     00  000   000  00000000  00000000  0000000  
    
    onWheel: (event) => 
        
        if Math.abs(event.deltaY) >= Math.abs(event.deltaX)
        
            scale = @scale * (1 - event.deltaY * 0.0003)
            scale = clamp 0.05, 100, scale
            
            if event.deltaY > 0
                @fadeCenter()
                
            @setScale scale, pos event 
        else
            
            @wheelSum ?= 0
            @wheelSum += event.deltaX * 0.002
            if Math.abs(@wheelSum) > 1
                @navigate parseInt @wheelSum
                @wheelSum = @wheelSum % 1
        
        event.stopPropagation()

    fadeCenter: (ff = 0.01) ->
        
        ib = boundingBox @items
        vb = boundingBox @scroll
        
        f1 = clamp 0, 1, 1.1-2*@scale
        f1 = f1 * f1 * f1 * f1
        
        f2 = clamp 0, 1, 1/(ib.h/vb.h)
        
        fade = clamp 0, 1, ff * f1 + 0.01 * ff * f2
        
        @offset.y = (1-fade) * @offset.y + fade * ((-(vb.h-ib.h)/2)/@scale)
        @offset.x = (1-fade) * @offset.x + fade * ((-(vb.w-ib.w)/2)/@scale)
    
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDrag: (drag, event) =>

        @offset.sub drag.delta.times 1/@scale
        @setScale @scale
        
    #  0000000  00000000  000   000  000000000  00000000  00000000   
    # 000       000       0000  000     000     000       000   000  
    # 000       0000000   000 0 000     000     0000000   0000000    
    # 000       000       000  0000     000     000       000   000  
    #  0000000  00000000  000   000     000     00000000  000   000  
    
    centerSelected: ->
  
        @setScale @scale
        @updateBorderSize()
        
        itemBox = boundingBox @selectedItem()
        brwsBox = boundingBox @items
        viewBox = boundingBox @scroll
        
        if itemBox.w / viewBox.w > 0.5
            @offset.x = -(brwsBox.x - itemBox.x + (viewBox.w - itemBox.w)/2) / @scale
        else
            border = ((viewBox.w / itemBox.w) % 1) * itemBox.w * 0.5
            if itemBox.x < viewBox.x + border
                @offset.x -= (viewBox.x - itemBox.x + border)/@scale
            if itemBox.x2 > viewBox.x2 - border
                @offset.x += (itemBox.x2 - viewBox.x2 + border)/@scale
            @fadeCenter()
            
        if itemBox.h / viewBox.h > 0.5
            @offset.y = -(brwsBox.y - itemBox.y + (viewBox.h-30 - itemBox.h)/2) / @scale
        else
            border = ((viewBox.h / itemBox.h) % 1) * itemBox.h * 0.5
            if itemBox.y < viewBox.y + border
                @offset.y -= (viewBox.y - itemBox.y + border)/@scale
            if itemBox.y2 > viewBox.y2 - border - 30
                @offset.y += (itemBox.y2 - viewBox.y2 + 30 + border)/@scale
            @fadeCenter()

        @setScale @scale
        @updateBorderSize()
                                
    # 000   000   0000000   000   000  000   0000000    0000000   000000000  00000000  
    # 0000  000  000   000  000   000  000  000        000   000     000     000       
    # 000 0 000  000000000   000 000   000  000  0000  000000000     000     0000000   
    # 000  0000  000   000     000     000  000   000  000   000     000     000       
    # 000   000  000   000      0      000   0000000   000   000     000     00000000  
    
    navigate: (dir) ->
        
        current = @selectedItem()
        oldIndex = elem.childIndex current
        newIndex = clamp 0, current.parentNode.children.length-1, oldIndex+dir
        if oldIndex != newIndex
            @selectIndex newIndex

    selectIndex: (index) ->
        
        @updateBorderSize()
        
        @selectedItem()?.classList.remove 'selected'
        
        @items.children[index]?.classList.add 'selected'
        @centerSelected()
    
    selectedFile: -> @selectedItem().getAttribute 'file'
    selectedItem: -> $ '.selected', @element
        
    updateBorderSize: ->
        
        borderWidth = 1.0/@scale
        if borderWidth != @borderWidth
            @borderWidth = borderWidth
            setStyle '.browserItem', 'border', "#{borderWidth}px solid transparent"
            setStyle '.browserItem.selected', 'border', "#{borderWidth}px solid white"
            setStyle '.browserItemTitleButton,.browserItemTitleClose', 'font-size', "#{clamp 12, 128, 12/@scale}px"
        
    #  0000000  000000000   0000000   00000000   000000000  
    # 000          000     000   000  000   000     000     
    # 0000000      000     000000000  0000000       000     
    #      000     000     000   000  000   000     000     
    # 0000000      000     000   000  000   000     000     
    
    onStart: (drag, event) =>
        
        if elem.upAttr event.target, 'file'
            @selectIndex elem.childIndex elem.upElem event.target, attr: 'file'
        
    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onStop: (drag, event) =>
        
        if drag.startPos == drag.lastPos
            if file = elem.upAttr event.target, 'file'
                @openFile file
                
    openFile: (file) ->
        
        @stage.load file
        @stage.centerSelection()
        @close()
                
    close: => @kali.closeBrowser()

    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) => 

        {mod, key, combo, char} = keyinfo.forEvent event
        
        switch combo
            
            when 'left'           then @navigate -1
            when 'right'          then @navigate +1
            when 'up'             then @navigate -@columns
            when 'down'           then @navigate +@columns
            when 'command+='      then return @zoom +1
            when 'command+-'      then @zoom -1
            when 'esc'            then @close()
            when 'return', 'enter', '.'     then @openFile @selectedFile()
            when 'command+e', 'e' then @zoomSelected()
            when 'command+0'      then @zoomAll()
            when 'backspace', 'delete' then @delItem @selectedItem()
                
        if combo.startsWith 'command' then return
        
        stopEvent event
    
module.exports = Browser

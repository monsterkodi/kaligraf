
# 0000000    00000000    0000000   000   000   0000000  00000000  00000000 
# 000   000  000   000  000   000  000 0 000  000       000       000   000
# 0000000    0000000    000   000  000000000  0000000   0000000   0000000  
# 000   000  000   000  000   000  000   000       000  000       000   000
# 0000000    000   000   0000000   00     00  0000000   00000000  000   000

{ setStyle, childIndex, stopEvent, keyinfo, drag, elem, prefs, resolve, fs, clamp, pos, log, $, _ } = require 'kxk'

{ winTitle } = require './utils'

class Browser

    constructor: (@kali, @files) ->

        @element = elem 'div', class: 'browser fill'
        @element.tabIndex = 100
        @element.addEventListener 'wheel',   @onWheel
        @element.addEventListener 'keydown', @onKeyDown
        
        @scale  = 1
        @offset = pos 0,0
        if @files.length > 1 then @offset.x = 1600
        
        @title = winTitle close:@onClose, class: 'browserTitle'
        @element.appendChild @title 
        
        @scroll = elem class: 'browserScroll'
        @element.appendChild @scroll
        
        @items = elem class: 'browserItems'
        @scroll.appendChild @items
                
        @kali.insertAboveTools @element
        
        for file in @files
            @addFile file
        
        @items.children[Math.min(1, @files.length-1)].classList.add 'selected'
            
        prefs.set 'browser:open', true
            
        @drag = new drag
            target: @element
            onMove: @onDrag
            onStop: @onStop
        
        @element.focus()
        @resize()
        
    # 0000000    00000000  000      
    # 000   000  000       000      
    # 000   000  0000000   000      
    # 000   000  000       000      
    # 0000000    00000000  0000000  
    
    del: -> 
        
        @drag.deactivate()
        prefs.set 'browser:open', false
        @element.remove()

    onDelFile: (event) => @delItem event.target.parentNode.parentNode
        
    delItem: (item) ->
        
        file = item.getAttribute 'file'
        recent = prefs.get 'recent'
        _.pull recent, file
        prefs.set 'recent', recent
        
        if item == @selectedItem() and @items.children.length > 1
            index = clamp 0, @items.children.length-2, childIndex item
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
            svg = fs.readFileSync resolve(file), encoding: 'utf8'
        catch e
            log 'error', e
            return
        
        item = elem 'span', class: 'browserItem'
        text = winTitle text:file, class: 'browserItemTitle', close:@onDelFile
        view = elem class: 'browserItemView'
        
        item.setAttribute 'file', file
        item.appendChild text
        item.appendChild view
        
        view.innerHTML = svg
        
        @items.appendChild item
                
    # 00000000   00000000   0000000  000  0000000  00000000    
    # 000   000  000       000       000     000   000         
    # 0000000    0000000   0000000   000    000    0000000     
    # 000   000  000            000  000   000     000         
    # 000   000  00000000  0000000   000  0000000  00000000    
    
    resize: ->
        
        br = @element.getBoundingClientRect()
        @setScale br.height/1400, pos(br.width/2, br.height/2)

    #  0000000   0000000   0000000   000      00000000  
    # 000       000       000   000  000      000       
    # 0000000   000       000000000  000      0000000   
    #      000  000       000   000  000      000       
    # 0000000    0000000  000   000  0000000  00000000  
    
    setScale: (scale, eventPos, fade=1) ->
        
        br = @element.getBoundingClientRect()
        
        oldscl = @scale
        oldoff = @offset.times @scale
        relpos = pos eventPos.x / br.width, eventPos.y / br.height
        
        @scale = scale
        
        @offset.y = (oldoff.y + relpos.y * br.height) / oldscl - relpos.y * br.height / @scale
            
        if br.height/@scale >= 1400
            @offset.y = ((1-fade) * @offset.y + fade * (-br.height/2/@scale + 700))
        
        @offset.x = (oldoff.x + relpos.x * br.width) / oldscl - relpos.x * br.width / @scale
        @items.style.transform = "scale(#{@scale}, #{@scale}) translate(#{-@offset.x}px, #{-@offset.y}px)"

    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    zoom: (dir) ->
        
        br = @element.getBoundingClientRect()
        
        @setScale @scale * (1 + dir * 0.5), pos br.width/2, br.height/2
        
    zoomSelected: ->
        
        br = @element.getBoundingClientRect()
        
        @resize()   
        @centerSelected()
        
    centerSelected: ->
        
        br = @element.getBoundingClientRect()
        
        @setOffsetX 1700 * childIndex(@selectedItem()) - (br.width/2/@scale - 750)
        
    #  0000000   00000000  00000000   0000000  00000000  000000000  000   000  
    # 000   000  000       000       000       000          000      000 000   
    # 000   000  000000    000000    0000000   0000000      000       00000    
    # 000   000  000       000            000  000          000      000 000   
    #  0000000   000       000       0000000   00000000     000     000   000  
    
    setOffsetX: (offsetX) ->
        
        @offset.x = offsetX
        
        br = @element.getBoundingClientRect()
         
        if br.height/@scale >= 1400
            fade = 0.01
            @offset.y = ((1-fade) * @offset.y + fade * (-br.height/2/@scale + 700))
         
        @items.style.transform = "scale(#{@scale}, #{@scale}) translate(#{-@offset.x}px, #{-@offset.y}px)"
        
    # 000   000   0000000   000   000  000   0000000    0000000   000000000  00000000  
    # 0000  000  000   000  000   000  000  000        000   000     000     000       
    # 000 0 000  000000000   000 000   000  000  0000  000000000     000     0000000   
    # 000  0000  000   000     000     000  000   000  000   000     000     000       
    # 000   000  000   000      0      000   0000000   000   000     000     00000000  
    
    navigate: (dir) ->
        
        current = @selectedItem()
        if dir > 0 and not current.nextSibling then return
        if dir < 0 and not current.previousSibling then return
        
        # @setOffsetX @offset.x + dir * 1700
        
        current.classList.remove 'selected'
        if dir > 0 and current.nextSibling
            current.nextSibling.classList.add 'selected'
        else if current.previousSibling
            current.previousSibling.classList.add 'selected'
            
        @centerSelected()

    selectIndex: (index) ->
        
        @selectedItem()?.classList.remove 'selected'
        @items.children[index]?.classList.add 'selected'
        @centerSelected()
    
    # 000   000  000   000  00000000  00000000  000      
    # 000 0 000  000   000  000       000       000      
    # 000000000  000000000  0000000   0000000   000      
    # 000   000  000   000  000       000       000      
    # 00     00  000   000  00000000  00000000  0000000  
    
    onWheel: (event) => 
        
        if Math.abs(event.deltaY) > Math.abs(event.deltaX)
            
            scale = @scale * (1 - event.deltaY * 0.0003)
            scale = clamp 0.05, 100, scale
            @setScale scale, pos(event), 0.1
            
        else
            @setOffsetX @offset.x + 0.4 * event.deltaX / @scale
            
        event.stopPropagation()

    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDrag: (drag, event) =>

        @offset.sub drag.delta.times 1/@scale
        @items.style.transform = "scale(#{@scale}, #{@scale}) translate(#{-@offset.x}px, #{-@offset.y}px)"

    #  0000000  000000000   0000000   00000000   
    # 000          000     000   000  000   000  
    # 0000000      000     000   000  00000000   
    #      000     000     000   000  000        
    # 0000000      000      0000000   000        
    
    onStop: (drag, event) =>
        
        if drag.startPos == drag.lastPos
            file = event.target.getAttribute 'file'
            if file
                @openFile file
                
    openFile: (file) ->
        
        @kali.stage.setCurrentFile file
        @kali.stage.centerSelection()
        @close()
        
    selectedFile: -> @selectedItem().getAttribute 'file'
    selectedItem: -> $ '.selected', @element
        
    close: => @kali.closeBrowser()

    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) => 

        {mod, key, combo, char} = keyinfo.forEvent event
        
        switch combo
            
            when 'left'          then @navigate -1
            when 'right'         then @navigate +1
            when 'up',   'command+=' then return @zoom +1
            when 'down', 'command+-' then @zoom -1
            when 'esc'           then @close()
            when 'enter'         then @openFile @selectedFile()
            when 'command+0'     then @zoomSelected()
            when 'backspace', 'delete' then @delItem @selectedItem()
                
        if combo.startsWith 'command' then return
        
        stopEvent event
    
module.exports = Browser

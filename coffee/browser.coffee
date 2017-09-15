
# 0000000    00000000    0000000   000   000   0000000  00000000  00000000 
# 000   000  000   000  000   000  000 0 000  000       000       000   000
# 0000000    0000000    000   000  000000000  0000000   0000000   0000000  
# 000   000  000   000  000   000  000   000       000  000       000   000
# 0000000    000   000   0000000   00     00  0000000   00000000  000   000

{ stopEvent, keyinfo, elem, prefs, resolve, fs, log, _ } = require 'kxk'

{ winTitle } = require './utils'

class Browser

    constructor: (@kali, @files) ->

        @element = elem 'div', class: 'browser fill'
        @element.tabIndex = 100
        @element.addEventListener 'wheel',   @onWheel
        @element.addEventListener 'keydown', @onKeyDown
        
        @title = winTitle close:@onClose, text: 'Recent', class: 'browserTitle'
        @element.appendChild @title 
        
        @scroll = elem class: 'browserScroll'
        @element.appendChild @scroll
        
        @items = elem class: 'browserItems'
        @scroll.appendChild @items
                
        @kali.insertAboveTools @element
        
        for file in @files
            @addFile file
            
        @element.focus()
        
    del: -> 
        
        @element.remove()
        
    #  0000000   0000000    0000000    
    # 000   000  000   000  000   000  
    # 000000000  000   000  000   000  
    # 000   000  000   000  000   000  
    # 000   000  0000000    0000000    
    
    addFile: (file) ->

        svg = fs.readFileSync resolve(file), encoding: 'utf8'
        
        item = elem 'span', class: 'browserItem'
        text = winTitle text:file, class: 'browserItemTitle', close:@delFile
        view = elem class: 'browserItemView'
        
        item.setAttribute 'file', file
        item.appendChild text
        item.appendChild view
        
        view.innerHTML = svg
        
        @items.appendChild item
        
        item.addEventListener 'click', @onClick
        
    delFile: (event) => 
        
        file = event.target.parentNode.parentNode.getAttribute 'file'
        recent = prefs.get 'recent'
        _.pull recent, file
        prefs.set 'recent', recent
        event.target.parentNode.parentNode.remove()
        stopEvent event
        
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
            when 'esc', 'enter'  then return @close()
                
        if combo.startsWith 'command' then return
        
        stopEvent event
        
    onWheel: (event) => 
        
        log 'browser wheel', event
        @scroll.scrollOffset += event.deltaY
        event.stopPropagation()

    onClick: (event) =>
        
        @kali.stage.load event.target.getAttribute 'file'
        @close()
        
    close: => @kali.closeRecent()
        
module.exports = Browser

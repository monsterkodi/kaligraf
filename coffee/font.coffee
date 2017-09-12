
# 00000000   0000000   000   000  000000000
# 000       000   000  0000  000     000   
# 000000    000   000  000 0 000     000   
# 000       000   000  000  0000     000   
# 000        0000000   000   000     000   


{ stopEvent, childIndex, keyinfo, elem, drag, clamp, post, log, _ } = require 'kxk'

{ winTitle } = require './utils'

Tool        = require './tool'
fontManager = require 'font-manager' 

class Font extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg

        @title = @element.appendChild elem 'div', class:'title', text: 'Font'

        bold   = elem 'span', class:'toolPlus',  text:'b'
        italic = elem 'span', class:'toolMinus', text:'i'               
        
        @bold   = false
        @italic = false
        @weight = 'normal'
        @style  = 'normal'
        @family = 'Helvetica'
        
        post.on 'font', @onFont
        
        bold  .addEventListener 'mousedown', @onBold
        italic.addEventListener 'mousedown', @onItalic
        
        boldItalic = elem 'div', class:'toolPlusMinus'
        boldItalic.appendChild bold
        boldItalic.appendChild italic
        @element.appendChild boldItalic
        @element.focus()
        
    onBold:   (event) => 
        stopEvent event  
        @bold   = !@bold
        @weight = @bold and 'bold' or 'normal'
        post.emit 'font', 'weight', @weight
        
    onItalic: (event) => 
        stopEvent(event) 
        @italic = !@italic
        @style  = @italic and 'italic' or 'normal'
        post.emit 'font', 'style', @style
        
    onFont: (prop, value) =>
        if prop == 'family'
            @family = value
            @title.style.fontFamily = @family
        
    onClick: (event) => 
        super event
        @hideChildren()
        if @list? 
            @list.toggleDisplay()
        else
            @list = new FontList @kali
            @list.show()

# 000      000   0000000  000000000  
# 000      000  000          000     
# 000      000  0000000      000     
# 000      000       000     000     
# 0000000  000  0000000      000     

class FontList
    
    constructor: (@kali) ->
        
        @element = elem 'div', class: 'fontList'
        @element.style.left = "#{120}px"
        @element.style.top  = "#{60}px"
        @element.tabIndex   = 100
        
        title   = winTitle text:'Fonts', close:@onClose
        @scroll = elem 'div', class: 'fontListScroll'
        
        @element.appendChild title
        @element.appendChild @scroll
        
        @drag = new drag
            target: title
            onMove: (drag) => 
                @element.style.left = "#{parseInt(@element.style.left) + drag.delta.x}px"
                @element.style.top  = "#{parseInt(@element.style.top)  + drag.delta.y}px"
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
        @element.addEventListener 'keydown', @onKeyDown
        @scroll.addEventListener  'click',   @onClick
                
        @fonts = fontManager.getAvailableFontsSync()
        @fonts = _.uniqWith @fonts, (a,b) -> a.family == b.family
        @fonts.sort (a,b) -> a.family.localeCompare b.family
        for font in @fonts
            fontElem = elem 'div', class:'fontElem'
            fontElem.style.fontFamily = font.family
            fontElem.innerHTML = font.family
            @scroll.appendChild fontElem

        @kali.insertBelowTools @element
          
    show: -> @element.style.display = 'initial'; @element.focus()
    hide: -> @element.style.display = 'none';    @element.blur()
    toggleDisplay: -> if @element.style.display == 'none' then @show() else @hide()
    
    onClose: => @hide()
    
    active: -> @scroll.querySelector '.active'
    activeIndex: -> @active() and childIndex(@active()) or 0
        
    navigate: (dir) -> @select @activeIndex() + dir
        
    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    select: (index) ->
        
        index = clamp 0, @scroll.children.length-1, index
        @active()?.classList.remove 'active'
        @scroll.children[index].classList.add 'active'
        @active().scrollIntoViewIfNeeded false
        post.emit 'font', 'family', @active().innerHTML

    onClick: (event) => @select childIndex event.target
    
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        switch combo
            
            when 'up', 'left'    then @navigate -1
            when 'down', 'right' then @navigate +1
            when 'command+left'  then @select 0
            when 'command+right' then @select @scroll.children.length-1
            when 'command+up'    then @navigate -10
            when 'command+down'  then @navigate +10
            when 'esc', 'enter'  then @hide()
            else
                log combo
    
module.exports = Font


# 00000000   0000000   000   000  000000000  000      000   0000000  000000000
# 000       000   000  0000  000     000     000      000  000          000   
# 000000    000   000  000 0 000     000     000      000  0000000      000   
# 000       000   000  000  0000     000     000      000       000     000   
# 000        0000000   000   000     000     0000000  000  0000000      000   

{ stopEvent, childIndex, keyinfo, elem, drag, clamp, last, post, log, _ } = require 'kxk'

{ winTitle } = require './utils'

fontManager = require 'font-manager' 

fontGroups = 
    sans: [
        'Arial'
        'Arial Black'
        'Arial Narrow'
        'Arial Rounded MT Bold'
        'Arial Unicode MS'
        'Helvetica'
        'Helvetica Neue'
        'Impact'
        'PT Sans'
        'PT Sans Caption'
        'PT Sans Narrow'
        'Verdana'        
    ]
    serif: [
        'PT Serif'
        'PT Serif Caption'
        'Times'
        'Times New Roman'
    ]
    mono: [
        'American Typewriter'
        'Andale Mono'
        'Courier'
        'Courier New'
        'Input Mono'
        'Input Mono Compressed'
        'Input Mono Condensed'
        'Input Mono Narrow'
        'Liberation Mono'        
        'Menlo'
        'Monaco'        
        'PT Mono'        
        'ProggyCleanTT'
        'ProggyOptiS'
        'ProggySmallTT'
        'ProggySquareTT'
        'ProggyTinyTT'
        'Source Code Pro'
    ]
    fancy: [
        'Chalkboard'
        'Chalkduster'
        'Comic Sans MS'
        'Herculanum'        
        'Marker Felt'
        'Noteworthy'
        'Papyrus'   
        'SignPainter'                
        'Snell Roundhand'
        'Trattatello'
        'Zapfino'
    ]
    other: [
        'Apple Braille'
        'Apple Chancery'
        'Apple SD Gothic Neo'
        'Apple Symbols'
        'AppleGothic'
        'AppleMyungjo'
        'Avenir'
        'Avenir Next'
        'Avenir Next Condensed'
        'Baskerville'
        'Big Caslon'
        'Bodoni 72'
        'Bodoni Ornaments'
        'Bradley Hand'
        'Brush Script MT'
        'Cochin'
        'Copperplate'
        'Cousine'
        'Didot'
        'Futura'
        'Geneva'
        'Georgia'
        'Gill Sans'
        'Hoefler Text'
        'Iowan Old Style'
        'Lucida Grande'
        'Luminari'
        'Microsoft Sans Serif'
        'Optima'
        'Palatino'
        'Phosphate'
        'Savoye LET'
        'Skia'
        'Symbol'
        'Tahoma'
        'Trebuchet MS'
        'Varela Round'
        'Webdings'
        'Wingdings'
    ]   
        
class FontList
    
    constructor: (@kali) ->
        
        @element = elem 'div', class: 'fontList'
        @element.style.left = "#{120}px"
        @element.style.top  = "#{60}px"
        @element.tabIndex   = 100
        
        title = winTitle close:@onClose, buttons: Object.keys(fontGroups).map (group) => 
            text:   group
            action: => @showGroup group
            
        @element.appendChild title 
        
        @drag = new drag
            target: title
            onMove: (drag) => 
                @element.style.left = "#{parseInt(@element.style.left) + drag.delta.x}px"
                @element.style.top  = "#{parseInt(@element.style.top)  + drag.delta.y}px"
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
        @element.addEventListener 'keydown', @onKeyDown
                
        fonts = fontManager.getAvailableFontsSync().map (font) -> font.family
        fonts = _.uniq fonts
        # fonts.sort (a,b) -> a.localeCompare b

        #  0000000   00000000    0000000   000   000  00000000    0000000  
        # 000        000   000  000   000  000   000  000   000  000       
        # 000  0000  0000000    000   000  000   000  00000000   0000000   
        # 000   000  000   000  000   000  000   000  000             000  
        #  0000000   000   000   0000000    0000000   000        0000000   
        
        @scrolls = {}
        
        for group,groupFonts of fontGroups
            
            scroll = elem 'div', class: 'fontListScroll'
            scroll.style.display = 'none'
            scroll.addEventListener  'click', @onClick
            @element.appendChild scroll
            @scrolls[group] = scroll
            
            addFont = (font) ->
                fontElem = elem 'div', class:'fontElem'
                fontElem.style.fontFamily = font
                fontElem.innerHTML = font
                scroll.appendChild fontElem
                _.pull fonts, font
            
            for groupFont in groupFonts
                if groupFont in fonts
                    addFont groupFont
            
            if group == last fontGroups
                for font in fonts
                    addFont font

        @kali.insertBelowTools @element
        
        @activeGroup = 'sans'
        @showGroup 'sans'
      
    showGroup: (group) ->
        @scrolls[@activeGroup].style.display = 'none'
        @activeGroup = group
        @scrolls[@activeGroup].style.display = 'initial'
        
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
        log @active().innerHTML
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
            when 'command+a', 'command+d', 'command+e' then return
            # else
                # log combo
                
        stopEvent event
        
module.exports = FontList

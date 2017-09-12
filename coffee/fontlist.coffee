
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
        'Apple SD Gothic Neo'
        'Apple Symbols'
        'AppleGothic'        
        'Arial'
        'Arial Black'
        'Arial Narrow'
        'Arial Rounded MT Bold'
        'Arial Unicode MS'
        'Avenir'
        'Avenir Next'
        'Avenir Next Condensed'
        'Bodoni 72'        
        'Cousine'
        'Futura'
        'Geneva'
        'Gill Sans'
        'Helvetica'
        'Helvetica Neue'
        'Impact'
        'Lucida Grande'
        'Microsoft Sans Serif'
        'Optima'        
        'PT Sans'
        'PT Sans Caption'
        'PT Sans Narrow'
        'Tahoma'
        'Trebuchet MS'
        'Varela Round'
        'Verdana'        
    ]
    serif: [
        'Apple Braille'   
        'AppleMyungjo'    
        'Baskerville'
        'Big Caslon'        
        'Cochin'
        'Copperplate'        
        'Didot'
        'Georgia'
        'Hoefler Text'        
        'Iowan Old Style'        
        'Palatino'
        'PT Serif'
        'PT Serif Caption'
        'Symbol'        
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
        'Apple Chancery'
        'Baoli SC'
        'Bradley Hand'
        'Brush Script MT'        
        'Chalkboard'
        'Chalkduster'
        'Comic Sans MS'
        'Hannotate TC'
        'HanziPen TC'
        'Herculanum'
        'Klee'
        'Libian SC'
        'Luminari' 
        'Marker Felt'
        'Nanum Pen Script'
        'Noteworthy'
        'Papyrus'   
        'Phosphate'        
        'Savoye LET'        
        'SignPainter'                
        'Skia'        
        'Snell Roundhand'
        'Trattatello'
        'Wawati SC'
        'Yuppy TC'
        'Zapfino'
    ]
    other: [
        'Bodoni Ornaments'
        'Webdings'
        'Wingdings'
    ]   
        
class FontList
    
    constructor: (@kali) ->
        
        @element = elem 'div', class: 'fontList'
        @element.style.left = "#{120}px"
        @element.style.top  = "#{60}px"
        @element.tabIndex   = 100
        
        @title = winTitle close:@onClose, buttons: Object.keys(fontGroups).map (group) => 
            text:   group
            class: "fontListGroup_#{group}"
            action: => @showGroup group
            
        @element.appendChild @title 
        
        @drag = new drag
            target: @title
            onMove: (drag) => 
                @element.style.left = "#{parseInt(@element.style.left) + drag.delta.x}px"
                @element.style.top  = "#{parseInt(@element.style.top)  + drag.delta.y}px"
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
        @element.addEventListener 'keydown', @onKeyDown
                
        fonts = fontManager.getAvailableFontsSync().map (font) -> font.family
        fonts = _.uniq fonts

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
            
            if group == last Object.keys fontGroups
                for font in fonts
                    addFont font if font?

        @kali.insertBelowTools @element
        
        @activeGroup = 'sans'
        @showGroup 'sans'
      
    #  0000000  000   000   0000000   000   000
    # 000       000   000  000   000  000 0 000
    # 0000000   000000000  000   000  000000000
    #      000  000   000  000   000  000   000
    # 0000000   000   000   0000000   00     00
    
    showGroup: (group) ->
        
        button = @title.querySelector ".fontListGroup_#{@activeGroup}"
        button.classList.remove 'active'
        @scrolls[@activeGroup].style.display = 'none'
        @activeGroup = group
        @scrolls[@activeGroup].style.display = 'block'
        button = @title.querySelector ".fontListGroup_#{@activeGroup}"
        button.classList.add 'active'
            
    show: -> @element.style.display = 'block'; @element.focus()
    hide: -> @element.style.display = 'none';  @element.blur()
    toggleDisplay: -> if @element.style.display == 'none' then @show() else @hide()
    
    onClose: => @hide()
    
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    active: -> @scrolls[@activeGroup].querySelector '.active'
    activeIndex: -> not @active() and -1 or childIndex @active()
        
    # 000   000   0000000   000   000  000   0000000    0000000   000000000  00000000  
    # 0000  000  000   000  000   000  000  000        000   000     000     000       
    # 000 0 000  000000000   000 000   000  000  0000  000000000     000     0000000   
    # 000  0000  000   000     000     000  000   000  000   000     000     000       
    # 000   000  000   000      0      000   0000000   000   000     000     00000000  
    
    navigate: (dir) -> @select @activeIndex() + dir
    navigateGroup: (dir) ->
        groups = Object.keys fontGroups 
        index = groups.indexOf @activeGroup
        index = clamp 0, groups.length-1, index+dir
        @showGroup groups[index]
        
    #  0000000  00000000  000      00000000   0000000  000000000  
    # 000       000       000      000       000          000     
    # 0000000   0000000   000      0000000   000          000     
    #      000  000       000      000       000          000     
    # 0000000   00000000  0000000  00000000   0000000     000     
    
    select: (index) ->
        scroll = @scrolls[@activeGroup]
        index = clamp 0, scroll.children.length-1, index
        @active()?.classList.remove 'active'
        scroll.children[index].classList.add 'active'
        @active().scrollIntoViewIfNeeded false
        post.emit 'font', 'family', @active().innerHTML
        # log ">#{@active().innerHTML}<"

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
            when 'command+left'  then stopEvent(event); @navigateGroup -1
            when 'command+right' then stopEvent(event); @navigateGroup +1
            when 'command+up'    then stopEvent(event); @select 0
            when 'command+down'  then stopEvent(event); @select @scrolls[@activeGroup].children.length-1
            when 'esc', 'enter'  then return @hide()
            # else
                # log combo
                
        if combo.startsWith 'command' then return
                
        stopEvent event
        
module.exports = FontList

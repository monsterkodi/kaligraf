###
00000000   0000000   000   000  000000000  000      000   0000000  000000000
000       000   000  0000  000     000     000      000  000          000   
000000    000   000  000 0 000     000     000      000  0000000      000   
000       000   000  000  0000     000     000      000       000     000   
000        0000000   000   000     000     0000000  000  0000000      000   
###

{ stopEvent, prefs, keyinfo, elem, drag, clamp, last, post, log, _ } = require 'kxk'

{ winTitle, ensureInSize } = require '../utils'

FontManager = require 'font-manager' 
# Shadow      = require '../shadow'

fontGroups = 
    Sans: [
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
        'Bahnschrift Light'
        'Calibri'
        'Calibri Light'
        'Candara'
        'Corbel'
        'Cousine'
        'Ebrima'
        'Franklin Gothic Medium'
        'Futura'
        'Geneva'
        'Gill Sans'
        'Helvetica'
        'Helvetica Neue'
        'Impact'
        'Lucida Grande'
        'Malgun Gothic'
        'Microsoft Sans Serif'
        'Microsoft JhengHei'
        'Microsoft PhagsPa'
        'Microsoft YaHei'
        'Microsoft YaHei Light'
        'Microsoft Yi Baiti'
        'Optima'        
        'PT Sans'
        'PT Sans Caption'
        'PT Sans Narrow'
        'Segoe UI Light'
        'Segoe UI'
        'Segoe UI Black'
        'Tahoma'
        'Trebuchet MS'
        'Varela Round'
        'Verdana'        
        'Yu Gothic Light'
        'Yu Gothic Medium'
        'Yu Gothic UI Semibold'
    ]
    Serif: [
        'Apple Braille'   
        'AppleMyungjo'    
        'Baskerville'
        'Big Caslon'
        'Bodoni 72'        
        'Cambria'
        'Cochin'
        'Didot'
        'Javanese Text'
        'Georgia'
        'Hoefler Text'        
        'Iowan Old Style'        
        'Leelawade UI Semilight'
        'Malgun Gothic Semilight'
        'Microsoft Himalaya'
        'Mongolian Baiti'
        'Nirmala UI Semilight'
        'Palatino'
        'Palatino Linotype'
        'PMingLiU-ExtB'
        'PT Serif'
        'PT Serif Caption'
        'Sitka Text'
        'Sitka Banner'
        'Sitka Display'
        'Sitka Heading'
        'Sitka Small'
        'Symbol'        
        'Times'
        'Times New Roman'
        'Yu Gothic Semilight'
    ]
    Mono: [
        'Andale Mono'
        'Consolas'
        'Courier'
        'Courier New'
        'Input Mono'
        'Input Mono Compressed'
        'Input Mono Condensed'
        'Input Mono Narrow'
        'Liberation Mono'        
        'Lucida Console'
        'Menlo'
        'MingLiU-ExtB'
        'Monaco'        
        'Meslo LG S'
        'PT Mono'        
        'ProggyCleanTT'
        'ProggyOptiS'
        'ProggySmallTT'
        'ProggySquareTT'
        'ProggyTinyTT'
        'SimSun'
        'Source Code Pro'
    ]
    Fancy: [
        'American Typewriter'                
        'Apple Chancery'
        'Baoli SC'
        'Bradley Hand'
        'Brush Script MT'        
        'Chalkboard'
        'Chalkduster'
        'Comic Sans MS'
        'Copperplate'        
        'Gabriola'
        'Hannotate TC'
        'HanziPen TC'
        'Herculanum'
        'Klee'
        'Libian SC'
        'Luminari' 
        'MV Boli'
        'Marker Felt'
        'Nanum Pen Script'
        'Noteworthy'
        'Papyrus'   
        'Phosphate'        
        'Savoye LET'        
        'Segoe Print'
        'Segoe Script'
        'SignPainter'                
        'Skia'        
        'Snell Roundhand'
        'Trattatello'
        'Wawati SC'
        'Yuppy TC'
        'Zapfino'
    ]
    Other: [
        'Bodoni Ornaments'
        'Webdings'
        'Wingdings'
    ]   
        
class FontList
    
    constructor: (@kali) ->
        
        @element = elem 'div', class: 'fontList'
        @element.style.left = "#{prefs.get 'fontlist:pos:x', 64}px"
        @element.style.top  = "#{prefs.get 'fontlist:pos:y', 34}px"
        @element.tabIndex   = 100
        
        @title = winTitle close:@onClose, buttons: Object.keys(fontGroups).map (group) => 
            text:   group
            class: "fontListGroup_#{group}"
            action: => @showGroup group
        @title.classList.add 'winTitleFontList' 
        @element.appendChild @title 
        
        @drag = new drag
            target: @title
            onMove: (drag) => 
                x = parseInt(@element.style.left) + drag.delta.x
                y = parseInt(@element.style.top)  + drag.delta.y
                prefs.set 'fontlist:pos:x', x
                prefs.set 'fontlist:pos:y', y
                @element.style.left = "#{x}px"
                @element.style.top  = "#{y}px"
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
        @element.addEventListener 'keydown', @onKeyDown
                
        fonts = FontManager.getAvailableFontsSync().map (font) -> font.family
        fonts = _.uniq fonts

        #  0000000   00000000    0000000   000   000  00000000    0000000  
        # 000        000   000  000   000  000   000  000   000  000       
        # 000  0000  0000000    000   000  000   000  00000000   0000000   
        # 000   000  000   000  000   000  000   000  000             000  
        #  0000000   000   000   0000000    0000000   000        0000000   
                
        @kali.insertBelowTools @element

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
                    
            @select prefs.get("fontlist:selected:#{group}", 0), group, emit:false
                            
        @activeGroup = @groupForFamily @kali.tool('font').family
        @activeGroup ?= 'Sans'
        @showGroup @activeGroup
        
        post.on 'resize', @onResize

    groupForFamily: (family) ->
        
        for group,groupFonts of fontGroups
            for child in @scrolls[group].children
                if child.innerHTML == family
                    return group
    
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
        @active().scrollIntoViewIfNeeded false
        @element.focus()
        post.emit 'font', 'family', @active().innerHTML
          
    isVisible:      -> @element.style.display != 'none'
    toggleDisplay:  -> @setVisible not @isVisible()
    setVisible: (v) -> if v then @show() else @hide()
    hide: -> 
        @element.style.display = 'none'
        @kali.focus()
        prefs.set 'fontlist:visible', false
        
    show: -> 
        @element.style.display = 'block'
        @element.focus()
        prefs.set 'fontlist:visible', true
        @active().scrollIntoViewIfNeeded false
    
    onClose: => @hide()
  
    onResize: (size) => 
        ensureInSize @element, size
    
    #  0000000    0000000  000000000  000  000   000  00000000  
    # 000   000  000          000     000  000   000  000       
    # 000000000  000          000     000   000 000   0000000   
    # 000   000  000          000     000     000     000       
    # 000   000   0000000     000     000      0      00000000  
    
    active: (group=@activeGroup) -> @scrolls[group].querySelector '.active'
    activeIndex: -> not @active() and -1 or elem.childIndex @active()
        
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
    
    select: (index, group=@activeGroup, opt) ->
        
        scroll = @scrolls[group]
        index = clamp 0, scroll.children.length-1, index
        @active(group)?.classList.remove 'active'
        scroll.children[index].classList.add 'active'
        @active(group).scrollIntoViewIfNeeded false
        if opt?.emit != false
            post.emit 'font', 'family', @active(group).innerHTML
        prefs.set "fontlist:selected:#{group}", index

    onClick: (event) => @select elem.childIndex event.target
    
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        
        switch combo
            
            when 'up'            then @navigate -1
            when 'down'          then @navigate +1
            when 'left'          then @navigateGroup -1
            when 'right'         then @navigateGroup +1
            when 'ctrl+up'       then stopEvent(event); @select 0
            when 'ctrl+down'     then stopEvent(event); @select @scrolls[@activeGroup].children.length-1
            when 'esc', 'enter'  then return @hide()
            # else
                # log combo
                
        if combo.startsWith 'ctrl' then return
                
        stopEvent event
        
module.exports = FontList

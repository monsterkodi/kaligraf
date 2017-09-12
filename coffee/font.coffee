
# 00000000   0000000   000   000  000000000
# 000       000   000  0000  000     000   
# 000000    000   000  000 0 000     000   
# 000       000   000  000  0000     000   
# 000        0000000   000   000     000   


{ stopEvent, elem, drag, clamp, post, log, _ } = require 'kxk'

{ winTitle } = require './utils'

Tool        = require './tool'
fontManager = require 'font-manager' 

class Font extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg

        @title = @element.appendChild elem 'div', class:'title', text: 'Font'

        bold = elem 'span', class:'toolPlus',  text:'b'
        ital = elem 'span', class:'toolMinus', text:'i'               
        
        @bold = false
        @ital = false
        
        bold.addEventListener 'mousedown', @onBold
        ital.addEventListener 'mousedown', @onItal
        
        boldItal = elem 'div', class:'toolPlusMinus'
        boldItal.appendChild bold
        boldItal.appendChild ital
        @element.appendChild boldItal
        
    onBold:  (event) => stopEvent(event) and @bold = !@bold
    onItal:  (event) => stopEvent(event) and @ital = !@ital
    onClick: (event) => 
        @list ?= new FontList @kali
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
        
        title  = winTitle text:'Fonts', close:@onClose
        scroll = elem 'div', class: 'fontListScroll'
        
        @element.appendChild title
        @element.appendChild scroll
        
        @drag = new drag
            target: title
            onMove: (drag) => 
                @element.style.left = "#{parseInt(@element.style.left) + drag.delta.x}px"
                @element.style.top  = "#{parseInt(@element.style.top)  + drag.delta.y}px"
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
                
        @fonts = fontManager.getAvailableFontsSync()
        @fonts = _.uniqWith @fonts, (a,b) -> a.family == b.family
        @fonts.sort (a,b) -> a.family.localeCompare b.family
        for font in @fonts
            fontElem = elem 'div', class:'fontElem'
            fontElem.style.fontFamily = font.family
            fontElem.innerHTML = font.family
            scroll.appendChild fontElem

        @kali.insertBelowTools @element
          
    show: -> @element.style.display = 'initial'    
    
    onClose: =>
        
        @element.style.display = 'none'
        
module.exports = Font


# 00000000   0000000   000   000  000000000
# 000       000   000  0000  000     000   
# 000000    000   000  000 0 000     000   
# 000       000   000  000  0000     000   
# 000        0000000   000   000     000   


{ stopEvent, elem, drag, clamp, post, log, _ } = require 'kxk'

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
    onClick: (event) => @list ?= new FontList @kali

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
        
        @drag = new drag
            target: @element
            onMove: (drag) => 
                @element.style.left = "#{parseInt(@element.style.left) + drag.delta.x}px"
                @element.style.top  = "#{parseInt(@element.style.top)  + drag.delta.y}px"
        
        @element.addEventListener 'wheel', (event) -> event.stopPropagation()
                
        @fonts = fontManager.getAvailableFontsSync()
        @fonts.sort (a,b) -> a.family.localeCompare b.family
        for font in @fonts
            fontElem = elem 'div', class:'fontElem'
            fontElem.style.fontFamily = font.family
            fontElem.innerHTML = font.family
            @element.appendChild fontElem

        @kali.insertBelowTools @element
                    
module.exports = Font

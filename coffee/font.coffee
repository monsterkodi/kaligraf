
# 00000000   0000000   000   000  000000000
# 000       000   000  0000  000     000   
# 000000    000   000  000 0 000     000   
# 000       000   000  000  0000     000   
# 000        0000000   000   000     000   


{ stopEvent, elem, clamp, post, log, _ } = require 'kxk'

Tool = require './tool'

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
    onClick: (event) => log 'onClick'
        
module.exports = Font

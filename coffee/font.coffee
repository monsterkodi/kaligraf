
# 00000000   0000000   000   000  000000000
# 000       000   000  0000  000     000   
# 000000    000   000  000 0 000     000   
# 000       000   000  000  0000     000   
# 000        0000000   000   000     000   

{ stopEvent, elem, post, log, _ } = require 'kxk'

Tool        = require './tool'
FontList    = require './fontlist'

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
        
    # 0000000     0000000   000      0000000    
    # 000   000  000   000  000      000   000  
    # 0000000    000   000  000      000   000  
    # 000   000  000   000  000      000   000  
    # 0000000     0000000   0000000  0000000    
    
    onBold:   (event) => 
        
        stopEvent event  
        @bold   = !@bold
        @weight = @bold and 'bold' or 'normal'
        post.emit 'font', 'weight', @weight
        
    # 000  000000000   0000000   000      000   0000000  
    # 000     000     000   000  000      000  000       
    # 000     000     000000000  000      000  000       
    # 000     000     000   000  000      000  000       
    # 000     000     000   000  0000000  000   0000000  
    
    onItalic: (event) => 
        
        stopEvent(event) 
        @italic = !@italic
        @style  = @italic and 'italic' or 'normal'
        post.emit 'font', 'style', @style
        
    # 00000000   0000000   000   000  000000000  
    # 000       000   000  0000  000     000     
    # 000000    000   000  000 0 000     000     
    # 000       000   000  000  0000     000     
    # 000        0000000   000   000     000     
    
    onFont: (prop, value) =>
        
        if prop == 'family'
            @family = value
            @title.style.fontFamily = @family
        
    #  0000000  000      000   0000000  000   000  
    # 000       000      000  000       000  000   
    # 000       000      000  000       0000000    
    # 000       000      000  000       000  000   
    #  0000000  0000000  000   0000000  000   000  
    
    onClick: (event) => 
        
        super event
        @hideChildren()
        if @list? 
            @list.toggleDisplay()
        else
            @list = new FontList @kali
            @list.show()
    
module.exports = Font

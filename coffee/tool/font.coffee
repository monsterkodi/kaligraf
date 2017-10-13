
# 00000000   0000000   000   000  000000000
# 000       000   000  0000  000     000   
# 000000    000   000  000 0 000     000   
# 000       000   000  000  0000     000   
# 000        0000000   000   000     000   

{ stopEvent, prefs, clamp, empty, elem, post, log, _ } = require 'kxk'

Tool     = require './tool'
FontList = require './fontlist'

class Font extends Tool

    constructor: (@kali, cfg) ->
        
        super @kali, cfg

        @bindStage 'setFontProp'
        
        @bold   = prefs.get 'font:bold',   false
        @italic = prefs.get 'font:italic', false
        @weight = prefs.get 'font:weight', 'normal'
        @style  = prefs.get 'font:style',  'normal'
        @family = prefs.get 'font:family', 'Helvetica'
        @size   = prefs.get 'font:size',   100
        
        @initTitle()
        
        @initSpin
            name:   'size'
            min:    1
            max:    9999
            reset:  100
            step:   [1,5,10,50]
            action: @setSize
            value:  @size
            
        @initButtons [
            text:  'b'
            name:  'bold'
            action: @onBold
            toggle: @bold
        ,
            text:   'i'
            name:   'italic'
            action: @onItalic
            toggle: @italic
        ]
                
        post.on 'font', @onFont
        post.on 'selection', @onSelection
                
    onSelection: =>    
        
        textItems = @stage.selectedTextItems()
        return if empty textItems
        
        weight = undefined
        style  = undefined
        size   = 0
        for item in textItems
            if weight == undefined
                weight = item.font 'font-weight'
            else if weight != item.font 'font-weight'
                weight = null
            if style == undefined
                style = item.font 'font-style'
            else if style != item.font 'font-style'
                style = null
            size += item.font 'font-size'
                            
        @setToggle 'bold', weight == 'bold'
        @setToggle 'italic', style == 'italic'
        @setSpinValue 'size', size/textItems.length
        
    # 0000000     0000000   000      0000000    
    # 000   000  000   000  000      000   000  
    # 0000000    000   000  000      000   000  
    # 000   000  000   000  000      000   000  
    # 0000000     0000000   0000000  0000000    
    
    onBold: (event) => 
        
        @bold   = @getToggle 'bold'
        @weight = @bold and 'bold' or 'normal'
        
        @title.style.fontWeight = @weight
        @button('bold').style.fontWeight = @weight
        @button('italic').style.fontWeight = @weight
        
        post.emit 'font', 'weight', @weight
        prefs.set 'font:bold',   @bold
        prefs.set 'font:weight', @weight
        
    # 000  000000000   0000000   000      000   0000000  
    # 000     000     000   000  000      000  000       
    # 000     000     000000000  000      000  000       
    # 000     000     000   000  000      000  000       
    # 000     000     000   000  0000000  000   0000000  
    
    onItalic: (event) => 
        
        @italic = @getToggle 'italic'
        @style  = @italic and 'italic' or 'normal'
        
        @title.style.fontStyle = @style
        @button('bold').style.fontStyle = @style
        @button('italic').style.fontStyle = @style
        
        post.emit 'font', 'style', @style
        prefs.set 'font:italic',   @italic
        prefs.set 'font:style',    @style
        
    # 00000000   0000000   000   000  000000000  
    # 000       000   000  0000  000     000     
    # 000000    000   000  000 0 000     000     
    # 000       000   000  000  0000     000     
    # 000        0000000   000   000     000     
    
    onFont: (prop, value) =>
        
        if prop == 'family'
            
            @family = value
            @title.style.fontFamily = @family
            prefs.set 'font:family', @family
            
        @stage.setFontProp prop, value        
        
    setSize: (@size) =>

        post.emit 'font', 'size', @size
        prefs.set 'font:size', @size
    
    # 000      000   0000000  000000000  
    # 000      000  000          000     
    # 000      000  0000000      000     
    # 000      000       000     000     
    # 0000000  000  0000000      000     
    
    toggleList: -> 
        
        if @list? 
            @list.toggleDisplay()
        else
            @showList()
    
    showList: ->
        
        @list = new FontList @kali
        @list.show()

    #  0000000  000000000   0000000    0000000   00000000    
    # 000          000     000   000  000        000         
    # 0000000      000     000000000  000  0000  0000000     
    #      000     000     000   000  000   000  000         
    # 0000000      000     000   000   0000000   00000000    
        
    setFontProp: (prop, value) ->
        
        textItems = @selectedTextItems()
        
        if not empty textItems
            @do()
            for item in textItems
                item.font prop, value
                
            @selection.update()
            @resizer.update()
            @done()
        
module.exports = Font

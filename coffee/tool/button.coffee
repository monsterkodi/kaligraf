
# 0000000    000   000  000000000  000000000   0000000   000   000
# 000   000  000   000     000        000     000   000  0000  000
# 0000000    000   000     000        000     000   000  000 0 000
# 000   000  000   000     000        000     000   000  000  0000
# 0000000     0000000      000        000      0000000   000   000

{ elem, upProp, stopEvent, log, $, _ } = require 'kxk'

Exporter = require '../exporter'

class Button
    
    initButtons: (buttons) ->
        
        span = elem class: 'toolButtons'
        @element.appendChild span
        
        for button in buttons
            btn = elem 'span'
            btn.innerHTML = button.text   if button.text?
            btn.name      = button.name   if button.name?
            
            if button.action?
                
                btn.classList.add 'toolButton'
                btn.action = button.action
            else
                btn.classList.add 'toolLabel'
                                
            if button.toggle?
                
                btn.toggle = button.toggle
                btn.classList.add 'toolToggle'
                btn.classList.toggle 'active', btn.toggle

            if button.choice?
                
                btn.choice = button.choice
                btn.toggle = button.toggle ? btn.choice == btn.name
                btn.classList.add 'toolToggle'
                btn.classList.toggle 'active', btn.toggle
                            
            if button.icon? or button.tiny? or button.small?

                btn.classList.add 'toolIcon'
                btn.classList.add 'toolTiny'  if button.tiny?
                btn.classList.add 'toolSmall' if button.small?
                btn.classList.remove 'toolButton' if not button.button

                btn.icon = button.icon ? button.tiny ? button.small
                
            if button.spin? 
                btn.spin = button.spin
                if not btn.name.endsWith 'reset'
                    btn.classList.add 'toolSpinButton' 
            
            span.appendChild btn
                                
            btn.addEventListener 'mousedown', @onButtonClick

            if btn.icon? then @setButtonIcon btn.name, btn.icon
            
        span
     
    button: (name) ->
        
        for btn in @element.querySelectorAll '.toolButton, .toolLabel, .toolIcon'
            if btn.name == name
                return btn
        
    setButtonIcon: (name, icon) -> 

        btn = @button name
        if not btn 
            log 'button.setButtonIcon -- no btn!?', name
            return
            
        if _.isArray icon
            icon = if btn.toggle then icon[1] else icon[0]
            
        if Exporter.hasSVG icon
            btn.innerHTML = Exporter.loadSVG icon
        else
            btn.innerHTML = Exporter.loadSVG 'rect'
            
        btn.firstChild.classList.add 'toolIconSVG'        

    #  0000000  000   000   0000000   000   000  
    # 000       000   000  000   000  000 0 000  
    # 0000000   000000000  000   000  000000000  
    #      000  000   000  000   000  000   000  
    # 0000000   000   000   0000000   00     00  
    
    showButton: (name, show) -> 
        
        if show? and not show then @hideButton name
        else 
            if @button(name).firstChild.tagName == 'svg'
                @button(name).firstChild.style.display = 'block'
            else
                @button(name).removeAttribute 'style' 

    hideButton: (name) -> 
        
        if @button(name).firstChild.tagName == 'svg'
            @button(name).firstChild.style.display = 'none'
        else
            @button(name).style.color = 'transparent'
        
    # 000000000   0000000    0000000    0000000   000      00000000  
    #    000     000   000  000        000        000      000       
    #    000     000   000  000  0000  000  0000  000      0000000   
    #    000     000   000  000   000  000   000  000      000       
    #    000      0000000    0000000    0000000   0000000  00000000  
    
    toggleButton: (name) -> @setToggle name, not @getToggle name
    getToggle:    (name) -> @button(name).toggle
        
    setToggle: (name, toggle=true) ->
        
        btn = @button name
        
        if btn.choice and toggle
            if active = $ btn.parentNode, '.active'
                active.classList.remove 'active'
                active.toggle = false
        
        btn.toggle = toggle
        btn.classList.toggle 'active', btn.toggle
        if _.isArray btn.icon
            @setButtonIcon name, btn.icon
        
    # 0000000    000000000  000   000        0000000  000      000   0000000  000   000  
    # 000   000     000     0000  000       000       000      000  000       000  000   
    # 0000000       000     000 0 000       000       000      000  000       0000000    
    # 000   000     000     000  0000       000       000      000  000       000  000   
    # 0000000       000     000   000        0000000  0000000  000   0000000  000   000  
    
    onButtonClick: (event) => 
                
        button = event.target.name
        
        if not button?
            button = upProp event.target, 'name'
        
        if button?
            @clickButton button, event 
            
        if not @hasParent()
            @kali.tools.collapseTemp()
            
        stopEvent event

    clickButton: (button, event) ->
        
        btn = @button button

        if btn.icon? and event? and not btn.spin?
            
            if event?.metaKey
                @kali.stage.addSVG Exporter.loadSVG btn.icon
                return

            if event?.ctrlKey
                btn.innerHTML = @kali.stage.copy()
                Exporter.saveSVG btn.icon, SVG.adopt btn.firstChild 
                return
                
        if btn.toggle?
            @toggleButton button
        
        btn.action?(event)    

module.exports = Button

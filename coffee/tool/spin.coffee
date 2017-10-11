
#  0000000  00000000   000  000   000
# 000       000   000  000  0000  000
# 0000000   00000000   000  000 0 000
#      000  000        000  000  0000
# 0000000   000        000  000   000

{ stopEvent, downElem, upElem, first, last, log, _ } = require 'kxk'

class Spin
        
    initSpin: (spin) ->
        
        spin.step ?= [1,5,10,50]
        
        span = @initButtons [
            tiny:   'spin-minus'
            button: true
            name:   spin.name + ' minus'
            action: @onSpin
            spin:   spin
        ,
            name:   spin.name + ' reset'
            action: @onSpin
            spin:   spin
        , 
            tiny:   'spin-plus'
            name:   spin.name + ' plus'
            button: true
            action: @onSpin
            spin:   spin
        ]
        
        @button(spin.name + ' reset').innerHTML = spin.str? and spin.str(spin.value) or spin.value
        
        span.addEventListener 'wheel', @onSpinWheel
        
    # 000   000  000   000  00000000  00000000  000      
    # 000 0 000  000   000  000       000       000      
    # 000000000  000000000  0000000   0000000   000      
    # 000   000  000   000  000       000       000      
    # 00     00  000   000  00000000  00000000  0000000  
    
    onSpinWheel: (event) => 
        
        if Math.abs(event.deltaX) >= Math.abs(event.deltaY)
            delta = event.deltaX
        else
            delta = -event.deltaY
        
        button = upElem event.target, prop:'spin'
        spin = button.spin
        step = spin.step[0]
        
        spin.wheel ?= 0
        spin.wheel = spin.wheel + delta * (spin.speed ? 1) * 0.01

        if Math.abs(spin.wheel) >= step
            if delta > 0
                delta = Math.floor(spin.wheel/step)*step
            else
                delta = Math.ceil(spin.wheel/step)*step
            spin.value = Math.round((spin.value + delta)/step)*step
            spin.wheel -= delta
            @doSpin spin
                
    #  0000000   000   000         0000000  00000000   000  000   000  
    # 000   000  0000  000        000       000   000  000  0000  000  
    # 000   000  000 0 000        0000000   00000000   000  000 0 000  
    # 000   000  000  0000             000  000        000  000  0000  
    #  0000000   000   000        0000000   000        000  000   000  
    
    onSpin: (event) => 
        
        stopEvent event
        button = upElem event.target, prop:'spin'
        
        spin = button.spin
        name = button.name
        
        part = last name.split ' '
        
        step = spin.step[0]
        step = spin.step[1] if event.metaKey
        step = spin.step[2] if event.altKey
        step = spin.step[3] if event.ctrlKey
            
        switch part
            when 'minus'
                spin.value = Math.round((spin.value - step)/step)*step
            when 'plus'
                spin.value = Math.round((spin.value + step)/step)*step
            when 'reset'
                if _.isArray spin.reset
                    if spin.value == first spin.reset
                        spin.reset.push spin.reset.shift()
                    spin.value = first spin.reset
                else
                    spin.value = spin.reset
                    
        @doSpin spin
           
    # 0000000     0000000          0000000  00000000   000  000   000  
    # 000   000  000   000        000       000   000  000  0000  000  
    # 000   000  000   000        0000000   00000000   000  000 0 000  
    # 000   000  000   000             000  000        000  000  0000  
    # 0000000     0000000         0000000   000        000  000   000  
    
    doSpin: (spin) ->
        
        @setSpinValue spin, spin.value
        
        spin.action spin.value
    
    getSpin: (name) -> downElem(@element, prop:'name', value:name+' reset')?.spin
        
    # 000   000   0000000   000      000   000  00000000  
    # 000   000  000   000  000      000   000  000       
    #  000 000   000000000  000      000   000  0000000   
    #    000     000   000  000      000   000  000       
    #     0      000   000  0000000   0000000   00000000  
    
    setSpinValue: (spin, value) ->
    
        if _.isString spin then spin = @getSpin spin
        
        spin.value = value
        
        if spin.min? 
            
            spin.value = Math.max spin.value, spin.min
            
            if spin.value <= spin.min
                @hideButton spin.name + ' minus'
            else
                @showButton spin.name + ' minus'
                
        if spin.max? 
            
            spin.value = Math.min spin.value, spin.max
            
            if spin.value >= spin.max
                @hideButton spin.name + ' plus'
            else
                @showButton spin.name + ' plus'
                
        if spin.str?
            valueStr = spin.str spin.value  
        else
            if (spin.value * 100) % 10
                valueStr = spin.value.toFixed 2
            else if (spin.value * 10) % 10
                valueStr = spin.value.toFixed 1
            else
                valueStr = spin.value.toFixed 0
            
        @button(spin.name + ' reset').innerHTML = valueStr
       
    # 0000000    000   0000000   0000000   0000000    000      00000000  
    # 000   000  000  000       000   000  000   000  000      000       
    # 000   000  000  0000000   000000000  0000000    000      0000000   
    # 000   000  000       000  000   000  000   000  000      000       
    # 0000000    000  0000000   000   000  0000000    0000000  00000000  
    
    disableSpin: (spin) ->
        
        if _.isString spin then spin = @getSpin spin
        
        @hideButton spin.name + ' minus'
        @hideButton spin.name + ' reset'
        @hideButton spin.name + ' plus'
        
    enableSpin: (spin) ->
        
        if _.isString spin then spin = @getSpin spin
        
        @showButton spin.name + ' minus'
        @showButton spin.name + ' reset'
        @showButton spin.name + ' plus'
        
module.exports = Spin

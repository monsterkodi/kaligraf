###
 0000000   00000000    0000000   0000000    000
000        000   000  000   000  000   000  000
000  0000  0000000    000000000  000   000  000
000   000  000   000  000   000  000   000  000
 0000000   000   000  000   000  0000000    000
###
{ kpos, _ } = require 'kxk'

{ boxPos, itemGradient } = require '../utils'

class Gradi

    constructor: (@object, @style) ->

        @name  = 'Gradi'
        @dots  = {}
        @lines = {}
        
        @edit  = @object.edit
        @stage = @edit.stage
        @trans = @edit.trans
        
    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->
        
        @clearDots()
        delete @gradient
        
    clearDots: ->
        
        for k,dot of @dots
            
            _.pull @edit.dotsel.dots, dot # @edit.dotsel.delDot dot
            
            delete dot.ctrl
            delete dot.dot
            dot.remove()
            
        for k,line of @lines
            line.remove()
        
        @dots  = {}
        @lines = {}
        
    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    update: ->
        
        if @gradient = itemGradient @object.item, @style
            @type = @gradient.type
            @initDots()
        else
            @del() 
        
    # 0000000     0000000   000000000
    # 000   000  000   000     000
    # 000   000  000   000     000
    # 000   000  000   000     000
    # 0000000     0000000      000

    initDots: ->
        
        @clearDots()
        @createDot 'from'
        @createDot 'to'
        @createDot 'radius' if @type == 'radial'
        @updateDots()
        
    updateDots: ->
        
        @updateDot 'from'
        @updateDot 'to'
        @updateDot 'radius' if @type == 'radial'
        
    index: -> @style
                        
    #  0000000  00000000   00000000   0000000   000000000  00000000  
    # 000       000   000  000       000   000     000     000       
    # 000       0000000    0000000   000000000     000     0000000   
    # 000       000   000  000       000   000     000     000       
    #  0000000  000   000  00000000  000   000     000     00000000  
    
    createDot: (dot) ->
  
        svg = @edit.svg.use @edit.defs[dot]
            
        svg.addClass "#{dot}Dot"                               
        svg.addClass "#{@style}Dot"                               
        svg.ctrl = @                                           
        svg.dot  = dot                                         
                                                               
        @dots[dot] = svg                                       
                                                               
        switch dot 
            when 'to'     then @createLine 'from-to'                                
            when 'radius' then @createLine 'radius'                                
                                                               
        svg

    # 000   000  00000000   0000000     0000000   000000000  00000000  
    # 000   000  000   000  000   000  000   000     000     000       
    # 000   000  00000000   000   000  000000000     000     0000000   
    # 000   000  000        000   000  000   000     000     000       
    #  0000000   000        0000000    000   000     000     00000000  
    
    updateDot: (dot) ->
        
        svg = @dots[dot]
        
        if not svg?
            log 'Gradi.updateDot no svg?', dot
            return
             
        relPos = switch dot
            
            when 'radius'
                if @gradient.attr('r')
                    kpos @gradient.attr('fx')+@gradient.attr('r'), @gradient.attr('fy')
                else
                    kpos 0.5, 0
                    
            when 'from'   
                
                if @type == 'radial' 
                    if @gradient.attr('fx') and @gradient.attr('fy')
                        kpos @gradient.attr('fx'), @gradient.attr('fy')
                    else
                        kpos 0.5, 0.5
                else
                    if @gradient.attr('x1') and @gradient.attr('y1')
                        kpos @gradient.attr('x1'), @gradient.attr('y1')
                    else
                        kpos 0, 0
                        
            when 'to'   
                
                if @type == 'radial' 
                    if @gradient.attr('cx') and @gradient.attr('cy')
                        kpos @gradient.attr('cx'), @gradient.attr('cy')
                    else
                        kpos 0.5, 0.5
                else
                    if @gradient.attr('x2') and @gradient.attr('y2')
                        kpos @gradient.attr('x2'), @gradient.attr('y2')
                    else
                        kpos 0.5, 0
                
        bb = @object.item.bbox()
        relPos.mul kpos bb.width, bb.height
        relPos.add boxPos bb
        relPos.add @stage.viewPos().times -1
        dotPos = @trans.fullTransform @object.item, relPos
        
        svg.cx dotPos.x
        svg.cy dotPos.y

        if dot in ['from', 'to']
            @plotLine 'from-to'
            
        if dot == 'radius' or dot == 'from' and @type == 'radial'
            @plotLine 'radius'
                    
    # 000      000  000   000  00000000
    # 000      000  0000  000  000
    # 000      000  000 0 000  0000000
    # 000      000  000  0000  000
    # 0000000  000  000   000  00000000

    createLine: (line) ->

        @lines[line]     = @edit.linesWhite.line()
        @lines[line+'_'] = @edit.linesBlack.line()
        
    plotLine: (line) ->

        switch line
            when 'from-to'
                pos1 = kpos @dots['from'].cx(), @dots['from'].cy()
                pos2 = kpos @dots['to'].cx(),   @dots['to'].cy()
            when 'radius'
                pos1 = kpos @dots['from'].cx(),   @dots['from'].cy()
                pos2 = kpos @dots['radius'].cx(), @dots['radius'].cy()
            else
                log "Gradi.plotLine -- unhandled line #{line}?"
                return
        
        @lines[line    ]?.plot [[pos1.x, pos1.y], [pos2.x, pos2.y]]
        @lines[line+'_']?.plot [[pos1.x, pos1.y], [pos2.x, pos2.y]]

    #  0000000  00000000  000      00000000   0000000  000000000  00000000  0000000    
    # 000       000       000      000       000          000     000       000   000  
    # 0000000   0000000   000      0000000   000          000     0000000   000   000  
    #      000  000       000      000       000          000     000       000   000  
    # 0000000   00000000  0000000  00000000   0000000     000     00000000  0000000    
    
    setSelected: (dot, selected) ->
        
        if selected
            @dots[dot]?.addClass 'selected'
        else
            @dots[dot]?.removeClass 'selected'
            
    isSelected: (dot) -> @dots[dot]?.hasClass 'selected'
                
    # 00     00   0000000   000   000  00000000  
    # 000   000  000   000  000   000  000       
    # 000000000  000   000   000 000   0000000   
    # 000 0 000  000   000     000     000       
    # 000   000   0000000       0      00000000  
    
    moveDotsBy: (dots, delta) ->
        
        for dot in dots
            
            dot.cx dot.cx() + delta.x
            dot.cy dot.cy() + delta.y
            
            if dot.dot in ['from', 'to']
                @plotLine 'from-to'
                
            if dot.dot == 'radius' or dot.dot == 'from' and @type == 'radial'
                @plotLine 'radius'
                
        @calcGradient()
        
    #  0000000   0000000   000       0000000  
    # 000       000   000  000      000       
    # 000       000000000  000      000       
    # 000       000   000  000      000       
    #  0000000  000   000  0000000   0000000  
    
    calcGradient: ->
        
        bb = @object.item.bbox()
        
        from = kpos @dots['from'].cx(), @dots['from'].cy()
        to   = kpos @dots['to'].cx(),   @dots['to'].cy()
        
        from = @trans.fullInverse @object.item, from
        to   = @trans.fullInverse @object.item, to
        
        from.sub boxPos bb
        to.sub   boxPos bb
        
        from.sub @stage.viewPos()
        to.sub   @stage.viewPos()
        
        w = @trans.width  @object.item
        h = @trans.height @object.item

        from.mul kpos 1/w, 1/h
        to.mul   kpos 1/w, 1/h
        
        @gradient.from from.x, from.y
        @gradient.to   to.x,   to.y
        
        if @type == 'radial'
            
            radius = kpos @dots['radius'].cx(), @dots['radius'].cy()
            radius = @trans.fullInverse @object.item, radius
            radius.sub boxPos bb
            radius.mul kpos 1/w, 1/h
            @gradient.radius from.dist radius
            
module.exports = Gradi

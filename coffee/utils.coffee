# 000   000  000000000  000  000       0000000    
# 000   000     000     000  000      000         
# 000   000     000     000  000      0000000     
# 000   000     000     000  000           000    
#  0000000      000     000  0000000  0000000     

{ empty, clamp, elem, pos, log, _ } = require 'kxk'

uuid = require 'uuid/v4'

module.exports = 
    
    #  0000000  000   000   0000000   000  000000000  00000000  00     00   0000000  
    # 000       000   000  000        000     000     000       000   000  000       
    # 0000000    000 000   000  0000  000     000     0000000   000000000  0000000   
    #      000     000     000   000  000     000     000       000 0 000       000  
    # 0000000       0       0000000   000     000     00000000  000   000  0000000   
    
    svgItems: (item, opt) ->
        
        items = []
        
        if opt?.style
            if item.style opt.style
                items.push item
        else if opt?.attr
            if item.node.hasAttribute opt.attr
                items.push item
        else if opt?.type
            if item.type == opt.type
                items.push item
        else if opt?.types
            if item.type in opt.types
                items.push item
        else
            items.push item
            
        if _.isFunction item.children
            for child in item.children()
                items = items.concat module.exports.svgItems child
        items
    
    itemIDs: (items) -> (items.map (item) -> item.id()).join ''   
    
    uuid: (item) -> 
        item.id item.type[0].toUpperCase() + "-" + uuid().slice(0,8).splice 2,0,'-'
        log item.id()
        
    # 0000000     0000000   000   000  
    # 000   000  000   000   000 000   
    # 0000000    000   000    00000    
    # 000   000  000   000   000 000   
    # 0000000     0000000   000   000  
    
    boxForItems: (items, offset={x:0,y:0}) ->
        
        if empty items
            return new SVG.RBox() 
            
        bb = null
        for item in items
            b = item.rbox()
            bb ?= b
            bb = bb.merge b

        module.exports.moveBox bb, pos -offset.x, -offset.y

    bboxForItems: (items, offset={x:0,y:0}) ->
        
        if empty items
            return new SVG.BBox() 
            
        bb = null
        for item in items
            b = item.bbox()
            b = b.transform item.transform().matrix
            bb ?= b
            bb = bb.merge b

        module.exports.moveBox bb, pos -offset.x, -offset.y
                
    boxCenter: (box) -> pos box.x + box.width/2.0, box.y + box.height/2.0
    boxOffset: (box) -> pos box.x, box.y
    boxSize:   (box) -> pos box.width, box.height
    
    boxPos: (box, name='top left') ->
        
        p = module.exports.boxCenter box
        if name.includes 'left'  then p.x = box.x
        if name.includes 'right' then p.x = box.x2
        if name.includes 'top'   then p.y = box.y
        if name.includes 'bot'   then p.y = box.y2
        p

    opposide: (name) ->
        
        switch name
            when 'left'  then 'right'
            when 'right' then 'left'
            when 'top'   then 'bot'
            when 'bot'   then 'top'
            when 'top left'  then 'bot right'
            when 'top right' then 'bot left'
            when 'bot left'  then 'top right'
            when 'bot right' then 'top left'
            else 'center'
        
    zoomBox:  (box, zoom)  -> module.exports.scaleBox 1.0/zoom
    scaleBox: (box, scale) ->
        
        box.x      *= scale
        box.y      *= scale
        if box.width?  then box.width  *= scale
        if box.height? then box.height *= scale
        
        if box.cx? then box.cx *= scale
        if box.x2? then box.x2 *= scale
        if box.cy? then box.cy *= scale
        if box.y2? then box.y2 *= scale
        
        if box.w? then box.w = box.width
        if box.h? then box.h = box.height
        
        box

    moveBox: (box, delta) -> 
        
        box.x += delta.x
        box.y += delta.y
        if box.cx? then box.cx += delta.x
        if box.x2? then box.x2 += delta.x
        if box.cy? then box.cy += delta.y
        if box.y2? then box.y2 += delta.y
        
        box        

    #  0000000   00000000    0000000   000   000  
    # 000        000   000  000   000  000 0 000  
    # 000  0000  0000000    000   000  000000000  
    # 000   000  000   000  000   000  000   000  
    #  0000000   000   000   0000000   00     00  
    
    growBox: (box, percent=10) ->

        w = box.width * percent / 100
        box.width = box.width + 2*w
        box.x -= w
        
        h = box.height * percent / 100
        box.height = box.height + 2*h
        box.y -= h
        
        if box.w?  then box.w  = box.width
        if box.h?  then box.h  = box.height
        if box.x2? then box.x2 = box.x + box.width
        if box.y2? then box.y2 = box.y + box.height
        if box.cx? then box.cx = box.x + box.w/2
        if box.cy? then box.cy = box.y + box.y/2
        
        box
        
    # 00000000   00000000   0000000  000000000  
    # 000   000  000       000          000     
    # 0000000    0000000   000          000     
    # 000   000  000       000          000     
    # 000   000  00000000   0000000     000     
    
    rectSize:   (r) -> pos r.x2 - r.x, r.y2 - r.y
    rectWidth:  (r) -> r.x2 - r.x
    rectHeight: (r) -> r.y2 - r.y
    rectCenter: (r) -> pos(r.x,r.y).mid pos(r.x2,r.y2)
    rectOffset: (r) -> pos(r.x,r.y)
        
    # 000  000   000  000000000  00000000  00000000    0000000  00000000   0000000  000000000  
    # 000  0000  000     000     000       000   000  000       000       000          000     
    # 000  000 0 000     000     0000000   0000000    0000000   0000000   000          000     
    # 000  000  0000     000     000       000   000       000  000       000          000     
    # 000  000   000     000     00000000  000   000  0000000   00000000   0000000     000     
    
    rectsIntersect: (a, b) ->
        
        if a.x2 < b.x then return false
        if a.y2 < b.y then return false
        if b.x2 < a.x then return false
        if b.y2 < a.y then return false
        true
        
    # 000   000   0000000   00000000   00     00  
    # 0000  000  000   000  000   000  000   000  
    # 000 0 000  000   000  0000000    000000000  
    # 000  0000  000   000  000   000  000 0 000  
    # 000   000   0000000   000   000  000   000  
    
    normRect: (r) ->
        
        [sx, ex] = [r.x, r.x2]
        [sy, ey] = [r.y, r.y2]
        if sx > ex then [sx, ex] = [ex, sx]
        if sy > ey then [sy, ey] = [ey, sy] 
        x:sx, y:sy, x2:ex, y2:ey
    
    #  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000  
    # 000        000   000  000   000  000   000  000  000       0000  000     000     
    # 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     
    # 000   000  000   000  000   000  000   000  000  000       000  0000     000     
    #  0000000   000   000  000   000  0000000    000  00000000  000   000     000     
    
    colorGradient: (svg, f) ->
        
        c = parseInt 255 * clamp 0, 1, f*2
        h = parseInt 255 * clamp 0, 1, (f-0.5)*2
        
        svg.gradient 'linear', (stop) ->
            stop.at 0.0,   new SVG.Color r:c, g:h, b:h
            stop.at 1.0/6, new SVG.Color r:c, g:c, b:h
            stop.at 2.0/6, new SVG.Color r:h, g:c, b:h
            stop.at 3.0/6, new SVG.Color r:h, g:c, b:c
            stop.at 4.0/6, new SVG.Color r:h, g:h, b:c
            stop.at 5.0/6, new SVG.Color r:c, g:h, b:c
            stop.at 6.0/6, new SVG.Color r:c, g:h, b:h

    grayGradient: (svg) ->
        
        svg.gradient 'linear', (stop) ->
            stop.at 0.0, "#000"
            stop.at 1.0, "#fff"

    contrastColor: (c) ->

        if module.exports.colorBrightness(c) < 0.5
            new SVG.Color '#fff'
        else
            new SVG.Color '#000'
            
    colorBrightness: (c) -> c = new SVG.Color(c); (c.r + c.g + c.b)/(3*255)
    colorDist: (a,b) -> Math.abs(a.r-b.r) + Math.abs(a.g-b.g) + Math.abs(a.b-b.b)
            
    #  0000000  000   000  00000000   0000000  000   000  00000000  00000000    0000000  
    # 000       000   000  000       000       000  000   000       000   000  000       
    # 000       000000000  0000000   000       0000000    0000000   0000000    0000000   
    # 000       000   000  000       000       000  000   000       000   000       000  
    #  0000000  000   000  00000000   0000000  000   000  00000000  000   000  0000000   
    
    checkersPattern: (svg, s, c='#fff') ->
        s2 = s*2
        svg.pattern s2, s2, (add) ->
            add.rect(s2,s2).fill c
            add.rect(s,s)
            add.rect(s,s).move s,s 
            
    # 000   000  000  000   000  000000000  000  000000000  000      00000000  
    # 000 0 000  000  0000  000     000     000     000     000      000       
    # 000000000  000  000 0 000     000     000     000     000      0000000   
    # 000   000  000  000  0000     000     000     000     000      000       
    # 00     00  000  000   000     000     000     000     0000000  00000000  
    
    winTitle: (opt) ->
        
        clss = opt?.class ? 'winTitle'
        div = elem class:clss
        
        if opt.text?
            
            div.appendChild elem 'span', class:"#{clss}Text", text: opt.text
            
        if opt.buttons?
            
            for button in opt.buttons
                btn = elem 'button', class:"#{clss}Button", text: button.text
                btn.data = button.data if button.data?
                btn.addEventListener 'click', button.action
                btn.classList.add button['class'] if button['class']?
                div.appendChild btn
            
        if _.isFunction opt.close
            
            close = elem 'button', class:"#{clss}Close", text: 'X'
            close.addEventListener 'click', opt.close
            div.appendChild close
            
        div
   
    #  0000000   0000000   000   000   0000000  000000000  00000000    0000000   000  000   000  
    # 000       000   000  0000  000  000          000     000   000  000   000  000  0000  000  
    # 000       000   000  000 0 000  0000000      000     0000000    000000000  000  000 0 000  
    # 000       000   000  000  0000       000     000     000   000  000   000  000  000  0000  
    #  0000000   0000000   000   000  0000000      000     000   000  000   000  000  000   000  
    
    constrain: (drag, event) ->
        
        if event.shiftKey
    
            if not drag.shift?
                if Math.abs(drag.delta.x) >= Math.abs(drag.delta.y)
                    drag.shift = pos 1,0
                else
                    drag.shift = pos 0,1
            else
            
            drag.delta.x *= drag.shift.x
            drag.delta.y *= drag.shift.y
                    
        else
            delete drag.shift
            
        
# 000   000  000000000  000  000       0000000    
# 000   000     000     000  000      000         
# 000   000     000     000  000      0000000     
# 000   000     000     000  000           000    
#  0000000      000     000  0000000  0000000     

{ stopEvent, empty, last, clamp, elem, pos, log, _ } = require 'kxk'

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
    
    itemIDs: (items, j='') -> (items.map (item) -> item.id()).join j  
    
    id: (prefix) -> prefix + "-" + uuid().slice(0,8).splice 2,0,'-'
    uuid: (item) -> item.id module.exports.id item.type[0].toUpperCase()
                    
    # 00     00   0000000   000000000  00000000   000  000   000  
    # 000   000  000   000     000     000   000  000   000 000   
    # 000000000  000000000     000     0000000    000    00000    
    # 000 0 000  000   000     000     000   000  000   000 000   
    # 000   000  000   000     000     000   000  000  000   000  
    
    itemMatrix: (item) ->
        
        m = item.transform().matrix.clone()
        for ancestor in item.parents()
            m = ancestor.transform().matrix.multiply m            
        m
        
    # 0000000     0000000   000   000  
    # 000   000  000   000   000 000   
    # 0000000    000   000    00000    
    # 000   000  000   000   000 000   
    # 0000000     0000000   000   000  
    
    insideBox: (p, box) -> box.x <= p.x <= box.x2 and box.y <= p.y <= box.y2
    
    rboxForItems: (items, offset={x:0,y:0}) ->
        
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
            # b = item.bbox()
            b = module.exports.itemBox item
            continue if b.width == 0 == b.height 
            b = b.transform module.exports.itemMatrix item
            bb ?= b
            bb = bb.merge b

        if bb?
            module.exports.moveBox bb, pos -offset.x, -offset.y
        else
            new SVG.BBox()

    itemBox: (item) ->
        
        if item.type in ['mask', 'clipPath']
            g = item.doc().group()
            for child in item.children()
                clone = child.clone()
                g.add clone
            box = g.bbox()
            g.remove()
            box
        else
            item.bbox()            
            
    boxCenter: (box) -> pos box.x + box.width/2, box.y + box.height/2
    boxOffset: (box) -> pos box.x, box.y
    boxSize:   (box) -> pos box.width, box.height
    
    boxPos: (box, name='top left') ->
        
        return pos box.x, box.y if name == 'top left'
        
        p = module.exports.boxCenter box
        if name.includes 'left'  then p.x = box.x
        if name.includes 'top'   then p.y = box.y
        if name.includes 'right' then p.x = box.x2
        if name.includes 'bot'   then p.y = box.y2
        p

    opposide: (name) ->
        
        switch name
            when 'left'      then 'right'
            when 'right'     then 'left'
            when 'top'       then 'bot'
            when 'bot'       then 'top'
            when 'top left'  then 'bot right'
            when 'top right' then 'bot left'
            when 'bot left'  then 'top right'
            when 'bot right' then 'top left'
            else 'center'
        
    zoomBox:  (box, zoom)  -> module.exports.scaleBox 1.0/zoom
    scaleBox: (box, scale) ->
        
        box.x *= scale
        box.y *= scale
        if box.width?  then box.width  *= scale
        if box.height? then box.height *= scale
        
        if box.cx? then box.cx *= scale
        if box.cy? then box.cy *= scale
        if box.x2? then box.x2 *= scale
        if box.y2? then box.y2 *= scale
        
        if box.w? then box.w = box.width
        if box.h? then box.h = box.height
        
        box

    moveBox: (box, delta) -> 
        
        box.x += delta.x
        box.y += delta.y
        if box.cx? then box.cx += delta.x
        if box.cy? then box.cy += delta.y
        if box.x2? then box.x2 += delta.x
        if box.y2? then box.y2 += delta.y
        
        box        

    boundingBox: (element) ->
        
        cr = element.getBoundingClientRect()
        x:      cr.left
        y:      cr.top
        width:  cr.width
        height: cr.height
        w:      cr.width
        h:      cr.height
        cx:     cr.left+cr.width/2
        cy:     cr.top+cr.height/2
        x2:     cr.left+cr.width
        y2:     cr.top+cr.height
              
    emptyBox: (box) -> box.width == 0 and box.height == 0
                
    setBox: (box, key, value) ->
        
        switch key
            when 'width'
                box.w  = box.width = value
                box.x  = box.cx - box.w/2
                box.x2 = box.cx + box.w/2
            when 'height'
                box.h  = box.height = value
                box.y  = box.cy - box.h/2
                box.y2 = box.cy + box.h/2
        
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
        if box.cy? then box.cy = box.y + box.h/2
        
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

    itemGradient: (item, style) ->
        
        value = item.style style 
        if value.startsWith 'url'
            module.exports.urlGradient value
            
    itemFilter: (item) ->
        
        return item.filterer if item.filterer
        
        if filter = item.attr 'filter'
            if filter.startsWith 'url'
                id = filter.split('#')[1].replace ')', ''
                return SVG.get id

    gradientStops: (gradient) ->
        
        i = 0
        stops = []
        while stop = gradient.get i
            stops.push
                offset:  stop.attr 'offset'
                color:   stop.attr 'stop-color'
                opacity: stop.attr 'stop-opacity'
                index:   i
            i++
        stops
        
    gradientColor: (gradient, offset) ->
        
        stops = module.exports.gradientStops gradient
        i = f = 0
        if stops[0].offset >= offset
            prev = next = stops[0]
        else if stops[stops.length-1].offset <= offset
            prev = next = last stops
            i = stops.length
        else
            i++ while stops[i].offset <= offset
            prev = stops[i-1]
            next = stops[i]
            f = (offset - prev.offset) / (next.offset - prev.offset)
        color:   new SVG.Color(prev.color).morph(new SVG.Color(next.color)).at(f)
        opacity: prev.opacity + f * (next.opacity - prev.opacity)
        index:   i
        
    gradientType: (gradient) -> 
        
        gradient.type.replace 'Gradient', ''
        
    cloneGradient: (gradient, doc) ->
        
        doc  ?= gradient.doc()
        stops = module.exports.gradientStops gradient
        doc.gradient gradient.type, (stop) ->
            for stp in stops
                stop.at stp.offset, stp.color, stp.opacity

    urlGradient: (url) ->
        
        id = url.split('"')[1].slice 1
        if gradient = SVG.get id
            gradient.type = module.exports.gradientType gradient
            return gradient
            
    gradientUrl: (gradient) -> "url(\"##{gradient.id()}\")"
            
    copyStops: (fromGradient, toGradient) ->
        
        module.exports.setGradientStops toGradient, module.exports.gradientStops fromGradient
        
    setGradientStops: (gradient, stops) ->
        
        gradient.update (stop) ->
            for stp in stops
                stop.at stp.offset, stp.color, stp.opacity

    gradientState: (gradient) ->
        
        state = 
            type:    gradient.type
            stops:   module.exports.gradientStops gradient
            spread:  gradient.attr('spreadMethod') ? 'pad'
            
        switch gradient.type
            
            when 'radial'
                
                state.from   = x:gradient.attr('fx'), y:gradient.attr('fy')
                state.to     = x:gradient.attr('cx'), y:gradient.attr('cy')
                state.radius = x:gradient.attr('fx') + gradient.attr('r'), y:gradient.attr('fy')
                
            when 'linear'
                
                state.from   = x:gradient.attr('x1'), y:gradient.attr('y1')
                state.to     = x:gradient.attr('x2'), y:gradient.attr('y2')
            
        state
                
    setGradientState: (gradient, state) ->

        gradient.attr 'spreadMethod', state.spread if state.spread?
        
        switch state.type
            
            when 'radial'
                for attr in ['cx', 'cy', 'fx', 'fy', 'r']
                    gradient.attr attr, state[attr] if state[attr]?
                    
                if state.from?
                    gradient.attr fx:state.from.x, fy:state.from.y
                if state.from?
                    gradient.attr cx:state.to.x, cy:state.to.y
                if state.radius?
                    gradient.attr r:pos(state.from).dist pos(state.radius)
                    
            when 'linear'
                for attr in ['x1', 'y1', 'x2', 'y2']
                    gradient.attr attr, state[attr] if state[attr]?
                    
                if state.from?
                    gradient.attr x1:state.from.x, y1:state.from.y
                if state.from?
                    gradient.attr x2:state.to.x, y2:state.to.y
                    
        if not empty state.stops
            module.exports.setGradientStops gradient, state.stops
    
    #  0000000   0000000   000       0000000   00000000   
    # 000       000   000  000      000   000  000   000  
    # 000       000   000  000      000   000  0000000    
    # 000       000   000  000      000   000  000   000  
    #  0000000   0000000   0000000   0000000   000   000  
    
    contrastColor: (c) ->

        if module.exports.colorBrightness(c) < 0.5
            new SVG.Color '#fff'
        else
            new SVG.Color '#000'
            
    highlightColor: (c) ->

        if module.exports.colorBrightness(c) < 0.5
            new SVG.Color '#666'
        else
            new SVG.Color '#333'
            
    colorBrightness: (c) -> c = new SVG.Color(c); (c.r + c.g + c.b)/(3*255)
    colorDist: (a,b) -> Math.abs(a.r-b.r) + Math.abs(a.g-b.g) + Math.abs(a.b-b.b)
    
    invertColor: (c) -> c = new SVG.Color(c); new SVG.Color r:255-c.r, g:255-c.g, b:255-c.b 
            
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
            close.addEventListener 'mousedown', -> stopEvent event and opt.close event
            div.appendChild close
            
        div
   
    # 00000000  000   000   0000000  000   000  00000000   00000000  000  000   000   0000000  000  0000000  00000000  
    # 000       0000  000  000       000   000  000   000  000       000  0000  000  000       000     000   000       
    # 0000000   000 0 000  0000000   000   000  0000000    0000000   000  000 0 000  0000000   000    000    0000000   
    # 000       000  0000       000  000   000  000   000  000       000  000  0000       000  000   000     000       
    # 00000000  000   000  0000000    0000000   000   000  00000000  000  000   000  0000000   000  0000000  00000000  
    
    ensureInSize: (element, size) ->
        
        br = element.getBoundingClientRect()
        if br.left + br.width > size.x then element.style.left = "#{size.x - br.width}px"
        if br.top + br.height > size.y then element.style.top  = "#{size.y - br.height}px"
            
        br = element.getBoundingClientRect()
        if br.top  < 0 then element.style.top = '0'
        if br.left < 0 then element.style.left = '0'
        
        
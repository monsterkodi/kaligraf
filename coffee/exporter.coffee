
# 00000000  000   000  00000000    0000000   00000000   000000000  00000000  00000000 
# 000        000 000   000   000  000   000  000   000     000     000       000   000
# 0000000     00000    00000000   000   000  0000000       000     0000000   0000000  
# 000        000 000   000        000   000  000   000     000     000       000   000
# 00000000  000   000  000         0000000   000   000     000     00000000  000   000

{ resolve, fs, log, _ } = require 'kxk'

{ growBox, uuid } = require './utils'

class Exporter

    #  0000000  000   000   0000000   
    # 000       000   000  000        
    # 0000000    000 000   000  0000  
    #      000     000     000   000  
    # 0000000       0       0000000   
    
    @svg: (svg, opt) ->
        
        bb = svg.bbox()
        growBox bb

        svgStr = """
            <svg width="100%" height="100%"
            version="1.1"
            xmlns="http://www.w3.org/2000/svg" 
            xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:svgjs="http://svgjs.com/svgjs"
            """

        rgba = "#{opt.color.r}, #{opt.color.g}, #{opt.color.b}, #{opt.alpha}"

        svgStr += "\nstyle=\"stroke-linecap: round; stroke-linejoin: round; background: rgba(#{rgba});\""
        svgStr += "\nviewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        
        Exporter.clean svg
                
        for item in svg.children()                    
            svgStr += '\n'
            svgStr += item.svg()
            
        svgStr += '</svg>'

    #  0000000   0000000   000   000  00000000  
    # 000       000   000  000   000  000       
    # 0000000   000000000   000 000   0000000   
    #      000  000   000     000     000       
    # 0000000   000   000      0      00000000  
        
    @save: (svg, opt) ->
        
        fs.writeFileSync resolve(opt.file), Exporter.svg svg, opt
       
    #  0000000  000      00000000   0000000   000   000  
    # 000       000      000       000   000  0000  000  
    # 000       000      0000000   000000000  000 0 000  
    # 000       000      000       000   000  000  0000  
    #  0000000  0000000  00000000  000   000  000   000  
    
    @clean: (item) ->

        if item.node.getAttribute 'sodipodi:nodetypes'
            log "clean sodipodi: #{item.node.getAttribute 'sodipodi:nodetypes'}" 
            item.node.removeAttribute   'sodipodi:nodetypes'
            
        if item.style('opacity') == 'unset'
            log 'clear unset opacity'
            item.style 'opacity', null
         
        if item.node.hasAttributes()
            
            item.node.removeAttribute 'xmlns:svgjs'
            
            attr = item.node.attributes
            for i in [attr.length-1..0]
                if attr[i]?.name.startsWith('inkscape:')
                    log 'clean inkscape', item.node.getAttribute attr[i].name
                    item.node.removeAttribute attr[i].name
                if attr[i]?.name.startsWith('sodipodi:')
                    log 'clean sodipodi', item.node.getAttribute attr[i].name
                    item.node.removeAttribute attr[i].name

        if item.type == 'defs'
            if item.children?().length == 0 and item.node.innerHTML.length == 0
                # log 'clean defs', item.id(), item.children?().length, item.node.innerHTML
                item.remove()
        else if item.type.startsWith 'inkscape:'
            item.remove()
        else if item.type.startsWith 'sodipodi:'
            item.remove()
                    
        if _.isFunction item.children
            
            for child in item.children()
                Exporter.clean child
                
        else if item.type == 'text'
            
            for i in [0...item.lines().length()]
                Exporter.clean item.lines().get i 
        # else
            # log 'no children', item.type
                    
        log "opacity: #{item.node.getAttribute 'opacity'}" if item.node.getAttribute 'opacity'
        
    # 000  0000000     0000000  
    # 000  000   000  000       
    # 000  000   000  0000000   
    # 000  000   000       000  
    # 000  0000000    0000000   
    
    @cleanIDs: (items) ->

        ids = items.map (item) -> item.id() 
        
        # log 'cleanIDs', ids
        
        ids = []
        for item in items

            while item.id().startsWith('Svgjs') or item.id() in ids
                uuid item
                
            ids.push item.id()
                
module.exports = Exporter

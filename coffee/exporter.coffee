
# 00000000  000   000  00000000    0000000   00000000   000000000  00000000  00000000 
# 000        000 000   000   000  000   000  000   000     000     000       000   000
# 0000000     00000    00000000   000   000  0000000       000     0000000   0000000  
# 000        000 000   000        000   000  000   000     000     000       000   000
# 00000000  000   000  000         0000000   000   000     000     00000000  000   000

{ empty, resolve, fs, fileExists, log, _ } = require 'kxk'

{ bboxForItems, growBox, uuid } = require './utils'

class Exporter

    #  0000000  000   000   0000000   
    # 000       000   000  000        
    # 0000000    000 000   000  0000  
    #      000     000     000   000  
    # 0000000       0       0000000   
    
    @svg: (root, opt) ->
        
        bb = opt?.viewbox ? root.bbox()
        growBox bb

        svgStr = """
            <svg width="100%" height="100%"
            version="1.1"
            xmlns="http://www.w3.org/2000/svg" 
            xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:svgjs="http://svgjs.com/svgjs"
            """

        if opt?.color and opt?.alpha
            rgba = "background: rgba(#{opt.color.r}, #{opt.color.g}, #{opt.color.b}, #{opt.alpha});"
        else rgba = ''
        svgStr += "\nstyle=\"stroke-linecap: round; stroke-linejoin: round;#{rgba}\""
        svgStr += "\nviewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        
        Exporter.clean root
                
        for item in root.children()                    
            svgStr += '\n'
            svgStr += item.svg()
            
        svgStr += '</svg>'

    @itemSVG: (items, opt) ->

        bb = opt?.viewbox ? bboxForItems items
        
        svgStr = """
            <svg width="100%" height="100%"
            version="1.1"
            xmlns="http://www.w3.org/2000/svg" 
            """
        svgStr += "\nstyle=\"stroke-linecap: round; stroke-linejoin: round;\""
        svgStr += "\nviewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        
        for item in items
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

    @saveSVG: (name, svg) ->
        
        svgFile = "#{__dirname}/../svg/#{name}.svg"
        fs.writeFileSync svgFile, svg, encoding: 'utf8'

    @loadSVG: (name) ->
        
        svgFile = "#{__dirname}/../svg/#{name}.svg"
        # log 'loadSVG', svgFile
        if fileExists svgFile
            return fs.readFileSync svgFile, encoding: 'utf8'
        # else
            # log "Exporter.loadSVG -- warning: no such file #{svgFile}"
        null
        
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

        if item.type in ['defs', 'g']
            if item.children?().length == 0
                return item.remove()
        else if item.type.startsWith 'inkscape:'
            return item.remove()
        else if item.type.startsWith 'sodipodi:'
            return item.remove()
                    
        if _.isFunction item.children
            
            for child in item.children()
                Exporter.clean child
                
        else if item.type == 'text'
            
            for i in [0...item.lines().length()]
                Exporter.clean item.lines().get i 
        # else
            # log 'no children', item.type
                    
        # log "opacity: #{item.node.getAttribute 'opacity'}" if item.node.getAttribute 'opacity'
        
    # 000  0000000     0000000  
    # 000  000   000  000       
    # 000  000   000  0000000   
    # 000  000   000       000  
    # 000  0000000    0000000   
    
    @cleanIDs: (items) ->

        return if empty items
        
        ids = items.map (item) -> item.id() 
        
        # log 'cleanIDs', ids
        
        ids = []
        for item in items

            while not item.id()? or item.id().startsWith('Svgjs') or item.id() in ids
                uuid item
                
            ids.push item.id()
                
module.exports = Exporter

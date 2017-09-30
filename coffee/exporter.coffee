
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
        
        padding = not opt.padding? and 10 or opt.padding
        bb = growBox new SVG.BBox(opt?.viewbox ? root.bbox()), padding

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
        
        @clean root
                
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
        
        fs.writeFileSync resolve(opt.file), @svg svg, opt

    @saveSVG: (name, svg) ->
        
        fs.writeFileSync @svgFile(name), svg, encoding: 'utf8'

    @hasSVG: (name) -> fileExists @svgFile name
                
    @loadSVG: (name) ->
        
        if @hasSVG name
            return fs.readFileSync @svgFile(name), encoding: 'utf8'
        else
            log 'no such icon file', @svgFile(name)
        null

    @svgFile: (name) -> "#{__dirname}/../svg/#{name}.svg"
    
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
                @clean child
                
        else if item.type == 'text'
            
            for i in [0...item.lines().length()]
                @clean item.lines().get i 
        
    # 000  0000000     0000000  
    # 000  000   000  000       
    # 000  000   000  0000000   
    # 000  000   000       000  
    # 000  0000000    0000000   
    
    @cleanIDs: (items) ->

        return if empty items
        
        ids = []
        for item in items

            while not item.id()? or item.id().startsWith('Svgjs') or item.id() in ids
                uuid item
                
            ids.push item.id()
                
module.exports = Exporter

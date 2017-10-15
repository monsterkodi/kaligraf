
# 00000000  000   000  00000000    0000000   00000000   000000000  00000000  00000000 
# 000        000 000   000   000  000   000  000   000     000     000       000   000
# 0000000     00000    00000000   000   000  0000000       000     0000000   0000000  
# 000        000 000   000        000   000  000   000     000     000       000   000
# 00000000  000   000  000         0000000   000   000     000     00000000  000   000

{ elem, empty, resolve, path, fs, fileExists, log, _ } = require 'kxk'

{ bboxForItems, growBox, uuid, itemGradient, itemFilter, itemIDs } = require './utils'

class Exporter

    #  0000000  000   000   0000000   
    # 000       000   000  000        
    # 0000000    000 000   000  0000  
    #      000     000     000   000  
    # 0000000       0       0000000   
    
    @svg: (root, opt) ->

        bb = opt?.box
        if not bb?
            padding = not opt?.padding? and 10 or opt.padding
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
        
        @cleanGradients svg
        @cleanFilters   svg
        fs.writeFileSync resolve(opt.file), @svg(svg, opt), encoding: 'utf8'

    @saveSVG: (name, svg) ->
        
        @cleanGradients svg
        @cleanFilters   svg
        fs.writeFileSync @svgFile(name), @svg(svg), encoding: 'utf8'

    @hasSVG: (name) -> fileExists @svgFile name
                
    @loadSVG: (name) ->
        
        if @hasSVG name
            return fs.readFileSync @svgFile(name), encoding: 'utf8'
        else
            log 'no such icon file', @svgFile(name)
        null

    @svgFile: (name) -> "#{__dirname}/../svg/#{name}.svg"
    
    @export: (root, file, opt) ->
        
        svg = @svg root

        if path.extname(file) == '.svg'
            fs.writeFileSync file, svg, encoding: 'utf8'
        else
            padding = not opt?.padding? and 10 or opt.padding
            bb = new SVG.BBox(opt?.viewbox ? root.bbox())
            gb = growBox new SVG.BBox(bb), padding
            canvas = elem 'canvas'
            canvas.width  = gb.width
            canvas.height = gb.height
            document.body.appendChild canvas
            ctx = canvas.getContext '2d'
            url = window.URL.createObjectURL new Blob [svg], type: 'image/svg+xml;charset=utf-8'
            img = new Image()           
            img.onload = -> 
                ctx.drawImage img, (gb.width-bb.width)/2, (gb.height-bb.height)/2, bb.width, bb.height
                imgData = canvas.toDataURL 'image/png' 
                data = new Buffer imgData.slice(imgData.indexOf(',')+1), 'base64'
                fs.writeFile file, data, encoding:null, (err) -> 
                    log err if err?
                    window.URL.revokeObjectURL url
                    canvas.remove()
            img.src = url
    
    #  0000000  000      00000000   0000000   000   000  
    # 000       000      000       000   000  0000  000  
    # 000       000      0000000   000000000  000 0 000  
    # 000       000      000       000   000  000  0000  
    #  0000000  0000000  00000000  000   000  000   000  
    
    @clean: (item) ->

        if item.node.getAttribute 'sodipodi:nodetypes'
            log "clean sodipodi: #{item.node.getAttribute 'sodipodi:nodetypes'}" 
            item.node.removeAttribute 'sodipodi:nodetypes'
            
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

        # if item.type in ['defs', 'g']
        if item.type in ['g']
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

    #  0000000   00000000    0000000   0000000    000  00000000  000   000  000000000   0000000  
    # 000        000   000  000   000  000   000  000  000       0000  000     000     000       
    # 000  0000  0000000    000000000  000   000  000  0000000   000 0 000     000     0000000   
    # 000   000  000   000  000   000  000   000  000  000       000  0000     000          000  
    #  0000000   000   000  000   000  0000000    000  00000000  000   000     000     0000000   
    
    @cleanGradients: (item) ->
        
        keepGradients = new Set()
        childItems = @childItems item
        
        for item in childItems
            for style in ['fill', 'stroke']
                if gradient = itemGradient item, style 
                    keepGradients.add gradient.id()
                    
        for def in item.doc().defs().children()
            if def.type.includes 'Gradient'
                if not keepGradients.has def.id()
                    log 'Exporter.cleanGradients -- remove unused gradient', def.id()
                    def.remove()

    @cleanFilters: (item) ->
        
        keepFilters = new Set()
        childItems = @childItems item
        
        for item in childItems
            if filter = itemFilter item
                keepFilters.add filter.id()

        for def in item.doc().defs().children()
            if def.type == 'filter'
                if not keepFilters.has def.id()
                    # log 'Exporter.cleanFilters -- remove unused filter', def.id()
                    def.remove()
                    
    @childItems: (item) ->
        
        return [] if item.type == 'defs'
        items = [item] 
        if _.isFunction item.children
            for child in item.children()
                items = items.concat @childItems child
        items
        
    # 000  0000000     0000000  
    # 000  000   000  000       
    # 000  000   000  0000000   
    # 000  000   000       000  
    # 000  0000000    0000000   
    
    @cleanIDs: (items) ->

        return if empty items
        # log 'Exporter.cleanIDs', itemIDs items, ' '
        ids = []
        for item in items

            while not item.id()? or item.id().startsWith('Svgjs') or item.id() in ids
                uuid item
                
            ids.push item.id()
                
module.exports = Exporter

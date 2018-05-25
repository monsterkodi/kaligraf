###
00000000  000   000  00000000    0000000   00000000   000000000  00000000  00000000 
000        000 000   000   000  000   000  000   000     000     000       000   000
0000000     00000    00000000   000   000  0000000       000     0000000   0000000  
000        000 000   000        000   000  000   000     000     000       000   000
00000000  000   000  000         0000000   000   000     000     00000000  000   000
###

{ elem, empty, slash, fs, log, _ } = require 'kxk'

{ bboxForItems, growBox, uuid, itemGradient, itemFilter, itemIDs } = require './utils'

pretty = require 'pretty-data'

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

        svgStr = """<svg width="100%" height="100%" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs" """

        if opt?.color and opt?.alpha
            rgba = "background: rgba(#{opt.color.r}, #{opt.color.g}, #{opt.color.b}, #{opt.alpha});"
        else rgba = ''
        svgStr += "\nstyle=\"stroke-linecap: round; stroke-linejoin: round; stroke-miterlimit: 20; #{rgba}\""
        svgStr += "\nviewBox=\"#{bb.x} #{bb.y} #{bb.width} #{bb.height}\">"
        
        @clean root
                
        for item in root.children()                    
            svgStr += '\n'
            svgStr += item.svg()
            
        svgStr += '</svg>'
        
        svgStr = pretty.pd.xml svgStr
        
        svgStr

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
        fs.writeFileSync slash.resolve(opt.file), @svg(svg, opt), encoding: 'utf8'

    @saveSVG: (name, svg) ->
        
        @cleanGradients svg
        @cleanFilters   svg
        fs.writeFileSync @svgFile(name), @svg(svg), encoding: 'utf8'

    @hasSVG: (name) -> slash.fileExists @svgFile name
                
    @loadSVG: (name) ->
        
        if @hasSVG name
            return fs.readFileSync @svgFile(name), encoding: 'utf8'
        else
            log 'no such icon file', @svgFile(name)
        null

    @svgFile: (name) -> slash.join __dirname, "../svg/#{name}.svg"
    
    @export: (root, file, opt) ->
        
        svg = @svg root

        if slash.extname(file) == '.svg'
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
            item.node.removeAttribute 'sodipodi:nodetypes'
            
        if item.node.hasAttributes()
            
            item.node.removeAttribute 'xmlns:svgjs'
            
            attr = item.node.attributes
            for i in [attr.length-1..0]
                if attr[i]?.name.startsWith('inkscape:')
                    item.node.removeAttribute attr[i].name
                if attr[i]?.name.startsWith('sodipodi:')
                    item.node.removeAttribute attr[i].name

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
    
    @fixGradients: (doc) ->
        
        for child in doc.defs().children()
            if child.type in ['linearGradient', 'radialGradient']
                nodes = child.node.childNodes
                for index in [nodes.length-1..0]
                    node = nodes[index]
                    if node.tagName != 'stop'
                        node.remove()
    
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

        ids = []
        for item in items

            while not item.id()? or item.id().startsWith('Svgjs') or item.id() in ids
                uuid item
                
            ids.push item.id()
                
module.exports = Exporter

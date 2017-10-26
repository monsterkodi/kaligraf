
#  0000000  000   000  00000000    0000000   0000000   00000000 
# 000       000   000  000   000  000       000   000  000   000
# 000       000   000  0000000    0000000   000   000  0000000  
# 000       000   000  000   000       000  000   000  000   000
#  0000000   0000000   000   000  0000000    0000000   000   000

{ elem, clamp, fileExists, fileName, path, fs, log, _ } = require 'kxk' 

{ svgItems, growBox } = require './utils'

Exporter = require './exporter'

class Cursor

    @kali = null
    
    @forTool: (name, opt) ->
        
        name = 'text-cursor' if name == 'text'
        
        svgFile = "#{__dirname}/../svg/#{name}.svg"
        if not fileExists svgFile 
            log "no cursor file #{svgFile}"
            return 'default'
        
        try
            svgStr = fs.readFileSync svgFile, encoding: 'utf8'
        catch e
            log 'Cursor.forTool error:', e
            return 'default'

        tmpDiv = elem 'div'
        tmpDiv.innerHTML = svgStr
        
        svg = SVG.adopt tmpDiv.firstChild 
        
        if opt?.fill
            for item in svgItems(svg, style:'fill')
                item.style fill: opt.fill
                
        if opt?.stroke
            for item in svgItems(svg, style:'stroke')
                item.style stroke: opt.stroke
        
        if svg.children().length > 1
            items = svg.children()
            grp = svg.group()
            for item in items
                grp.add item

        svg.children()[0].filter (add) ->
            blur = add.offset(2, 2).in(add.sourceAlpha).gaussianBlur 4
            add.blend add.source, blur
                
        Exporter.clean svg
        
        tip = @calcTip svg, name
            
        cursorDir = path.join path.dirname(svgFile), 'cursor'
        fs.ensureDirSync cursorDir 
                        
        if opt?.fill or opt?.stroke
            svg.attr width: 32, height:32
            "url(data:image/svg+xml;base64,#{btoa svg.svg()}) #{tip.x} #{tip.y}, auto"
        else
            svgFileX1 = path.join cursorDir, tip.name + " x1.svg"
            svgFileX2 = path.join cursorDir, tip.name + " x2.svg"
            
            svg.attr width: tip.s, height:tip.s
            fs.writeFileSync svgFileX1, svg.svg(), encoding: 'utf8'
            svg.attr width: tip.s*2, height:tip.s*2
            fs.writeFileSync svgFileX2, svg.svg(), encoding: 'utf8'
            
            """-webkit-image-set( url("#{svgFileX1}") 1x, url("#{svgFileX2}") 2x ) #{tip.x} #{tip.y}, auto
            """

    @calcTip: (svg, name) ->
        
        for circle in svgItems(svg, type:'circle')
            if circle.style('stroke-opacity') == '0' and circle.style('fill-opacity') == '0'
                circlePos = @kali.trans.pos circle
                s = 32
                switch name
                    when 'rect', 'circle', 'ellipse'     then s = 16
                    when 'draw_drag', 'draw_move'        then s = 16
                    when 'rot top left', 'rot top right' then s = 22
                    when 'rot bot left', 'rot bot right' then s = 22
                    when 'rect', 'circle', 'ellipse'     then s = 16
                    when 'draw_drag', 'draw_move'        then s = 16
                    when 'triangle', 'triangle_square'   then s = 16
                    when 'text-cursor'
                        s = @kali.tool('font').size
                        s *= @kali.stage.zoom
                        s = Math.round clamp 20, 128, s
                        name = "#{name}-#{s}"
                        
                x = s * (circlePos.x-svg.viewbox().x) / svg.viewbox().width
                y = s * (circlePos.y-svg.viewbox().y) / svg.viewbox().height
                log 'gotcha!', name, x, y
                
                return x:x, y:y, s:s, name:name
        
        log "unhandled tip for  cursor#{name}"
        x:0, y:0, s:32, name:name
            
module.exports = Cursor

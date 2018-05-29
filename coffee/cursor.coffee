###
 0000000  000   000  00000000    0000000   0000000   00000000 
000       000   000  000   000  000       000   000  000   000
000       000   000  0000000    0000000   000   000  0000000  
000       000   000  000   000       000  000   000  000   000
 0000000   0000000   000   000  0000000    0000000   000   000
###

{ prefs, elem, clamp, slash, fs, log, _ } = require 'kxk' 

{ svgItems, growBox } = require './utils'

Exporter = require './exporter'

class Cursor

    @kali = null
    
    # 00000000   0000000   00000000   000000000   0000000    0000000   000      
    # 000       000   000  000   000     000     000   000  000   000  000      
    # 000000    000   000  0000000       000     000   000  000   000  000      
    # 000       000   000  000   000     000     000   000  000   000  000      
    # 000        0000000   000   000     000      0000000    0000000   0000000  
    
    @forTool: (name, opt) ->
        
        name = 'text-cursor' if name == 'text'
        
        svgFile = slash.resolve slash.join __dirname, "../img/tool/#{name}.svg"
        if not slash.fileExists svgFile 
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
            
        electron = require 'electron'
        userDir = electron.remote.app.getPath 'userData'
        cursorDir = slash.join userDir, 'cursor'
        
        fs.ensureDirSync slash.unslash cursorDir 
                        
        if opt?.fill or opt?.stroke
            svg.attr width: 32, height:32
            "url(data:image/svg+xml;base64,#{btoa svg.svg()}) #{tip.x} #{tip.y}, auto"
        else
            svgFileX1 = slash.join cursorDir, tip.name + " x1.svg"
            svgFileX2 = slash.join cursorDir, tip.name + " x2.svg"
            
            svg.attr width: tip.s, height:tip.s
            fs.writeFileSync slash.unslash(svgFileX1), svg.svg(), encoding: 'utf8'
            svg.attr width: tip.s*2, height:tip.s*2
            fs.writeFileSync slash.unslash(svgFileX2), svg.svg(), encoding: 'utf8'
            
            """-webkit-image-set( url("#{svgFileX1}") 1x, url("#{svgFileX2}") 2x ) #{tip.x} #{tip.y}, auto
            """

    #  0000000   0000000   000       0000000  000000000  000  00000000   
    # 000       000   000  000      000          000     000  000   000  
    # 000       000000000  000      000          000     000  00000000   
    # 000       000   000  000      000          000     000  000        
    #  0000000  000   000  0000000   0000000     000     000  000        
    
    @calcTip: (svg, name) ->
        
        s = 32  
        switch name
            when 'rot top left', 'rot top right' then s = 22
            when 'rot bot left', 'rot bot right' then s = 22
            when 'rect', 'circle', 'ellipse'     then s = 16
            when 'draw_drag', 'draw_move'        then s = 16
            when 'rect', 'circle', 'ellipse'     then s = 16
            when 'triangle', 'triangle_square'   then s = 16
            when 'text-cursor'
                s = @kali.tool('font').size
                s *= @kali.stage.zoom
                s = Math.round clamp 20, 128, s
                name = "#{name}-#{s}"
                
        box = svg.viewbox()
        x = s * -box.x / box.width
        y = s * -box.y / box.height
        x:x, y:y, s:s, name:name
        
module.exports = Cursor

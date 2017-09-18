
#  0000000  000   000  00000000    0000000   0000000   00000000 
# 000       000   000  000   000  000       000   000  000   000
# 000       000   000  0000000    0000000   000   000  0000000  
# 000       000   000  000   000       000  000   000  000   000
#  0000000   0000000   000   000  0000000    0000000   000   000

{ elem, fileExists, fileName, path, fs, log } = require 'kxk' 

{ svgItems } = require './utils'

Exporter = require './exporter'

class Cursor

    @forTool: (name, opt) ->
        
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
        svg.attr width: 32, height:32
        
        if opt?.fill
            for item in svgItems(svg, style:'fill')
                item.style fill: opt.fill
                
        if opt?.stroke
            for item in svgItems(svg, style:'stroke')
                item.style stroke: opt.stroke
        
        Exporter.clean svg
        
        o = 6
        x = o
        y = o
        s = 32
        switch name
            when 'loupe', 'zoom-in', 'zoom-out' then x = 10;   y = 9; 
            when 'rect', 'circle', 'ellipse'    then x =  7;   y = 7;   s = 16
            when 'draw_drag', 'draw_move'       then x =  7;   y = 7;   s = 16
            when 'pipette'                      then           y = 32-o; 
            when 'pan'                          then x = 12;   y = 8;    
            when 'edit hover'                   then x = 2;    y = 2;    
            when 'edit'                         then x = 4;    y = 4;    
            when 'triangle'                     then x = 7;    y = 3;   s = 16
            when 'triangle_square'              then x = 2;    y = 14;  s = 16
            when 'line'                         then x = 2;    y = 28
            when 'bezier_quad'                  then x = 16
            when 'polygon', 'polyline'          then x = 4;    y = 2;  s = 22
            when 'rot top left'                 then x = 18;   y = 18; s = 22
            when 'rot top right'                then x =  4;   y = 18; s = 22
            when 'rot bot left'                 then x = 18;   y =  4; s = 22
            when 'rot bot right'                then x =  4;   y =  4; s = 22
            when 'rot top'                      then x = 16;   y = 32-o
            when 'rot left'                     then x = 32-o; y = 16
            when 'rot right'                    then           y = 16
            when 'rot bot'                      then x = 16
            else "unhandled tip for  cursor#{name}"
            
        svgFileX1 = path.join path.dirname(svgFile), 'cursor', fileName(svgFile) + " x1.svg"
        svgFileX2 = path.join path.dirname(svgFile), 'cursor', fileName(svgFile) + " x2.svg"
        
        if opt?.fill or opt?.stroke
            "url(data:image/svg+xml;base64,#{btoa svg.svg()}) #{x} #{y}, auto"
        else
            svg.attr width: s, height:s
            fs.writeFileSync svgFileX1, svg.svg(), encoding: 'utf8'
            svg.attr width: s*2, height:s*2
            fs.writeFileSync svgFileX2, svg.svg(), encoding: 'utf8'
            
            """-webkit-image-set( url("#{svgFileX1}") 1x, url("#{svgFileX2}") 2x ) #{x} #{y}, auto
            """

module.exports = Cursor

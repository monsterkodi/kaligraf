
#  0000000  000   000  00000000    0000000   0000000   00000000 
# 000       000   000  000   000  000       000   000  000   000
# 000       000   000  0000000    0000000   000   000  0000000  
# 000       000   000  000   000       000  000   000  000   000
#  0000000   0000000   000   000  0000000    0000000   000   000

{ elem, fileExists, fs, log } = require 'kxk' 

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
        tipx = 0+o
        tipy = 0+o
        
        switch name
            when 'rect', 'circle', 'ellipse' then tipx = 16; tipy = 16
            when 'triangle'        then tipx = 16
            when 'bezier_quad'     then tipx = 16
            when 'pan'             then tipx = 12; tipy = 8
            when 'line'            then tipx = 2; tipy = 28
            when 'polygon'         then tipx = 4; tipy = 2
            when 'triangle_square' then tipy = 32-o
            when 'pipette'         then tipy = 32-o
            when 'loupe', 'zoom-in', 'zoom-out' then tipx = 10; tipy = 9
            when 'rot-tl'          then tipy = 32-o
            
        "url(data:image/svg+xml;base64,#{btoa svg.svg()}) #{tipx} #{tipy}, auto"

module.exports = Cursor

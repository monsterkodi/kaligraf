
# 00000000  0000000    000  000000000
# 000       000   000  000     000   
# 0000000   000   000  000     000   
# 000       000   000  000     000   
# 00000000  0000000    000     000  

{ post, elem, log, _ } = require 'kxk'

class Edit

    constructor: (@kali) ->

        @element = elem 'div', id: 'edit'
        @kali.element.appendChild @element
        
        @svg = SVG(@element).size '100%', '100%' 
        @svg.addClass 'editSVG'
        @svg.clear()
        
        post.on 'draw', @onDraw
        
    del: ->
        
        post.removeListener 'draw', @onDraw
        @svg.clear()
        @svg.remove()
        @element.remove()
        
    onDraw: (draw, action, index) =>
        
        log "Edit.onDraw action:#{action} index:#{index}", draw.posAt index
        
module.exports = Edit


# 00000000  000  000      00000000  000  000   000  00000000   0000000 
# 000       000  000      000       000  0000  000  000       000   000
# 000000    000  000      0000000   000  000 0 000  000000    000   000
# 000       000  000      000       000  000  0000  000       000   000
# 000       000  0000000  00000000  000  000   000  000        0000000 

{ post, elem, path, fileName, log, $, _ } = require 'kxk'

{ contrastColor } = require './utils'

class FileInfo

    constructor: (@kali) ->

        @element = elem id: 'fileInfo'
        @kali.element.insertBefore @element, @kali.stage.element.nextSibling
        
        @file = elem 'span', class: 'fileInfoText', click: -> post.emit 'tool', 'browse'
        @element.appendChild @file        
        
        @dirty = elem 'span', class: 'fileInfoDirty', click: -> post.emit 'tool', 'save'
        @element.appendChild @dirty
        @element.style.zIndex = 1000
        
        post.on 'stage', @onStage
        post.on 'undo',  @onUndo
        
    onStage: (action, info) =>
        
        if action in ['load', 'save', 'clear']
            @file.innerHTML = fileName info.file
        
    onUndo: (info) =>
        
        @dirty.style.display    = info.dirty and 'inline-block' or 'none'
        @dirty.style.background = info.dirty and '#f80' or '#222'
        
module.exports = FileInfo


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
        @kali.element.insertBefore @element, @kali.stage.element
        
        @file = elem 'span', class: 'fileInfoText'
        @element.appendChild @file
        
        post.on 'file',  @onFile
        # post.on 'stage', @onStage
        
    onFile: (file) =>
        
        @file.innerHTML = fileName file
        
    # onStage: (action, color) =>

module.exports = FileInfo

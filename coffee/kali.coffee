###
000   000   0000000   000      000  
000  000   000   000  000      000  
0000000    000000000  000      000  
000  000   000   000  000      000  
000   000  000   000  0000000  000  
###

{ post, win, title, keyinfo, stopEvent, empty, first, prefs, popup, elem, sw, sh, pos, log, $, _ } = require 'kxk'

w = new win 
    dir:    __dirname
    pkg:    require '../package.json'
    menu:   '../coffee/menu.noon'
    icon:   '../img/menu@2x.png'
    scheme: false

Tools    = require './tool/tools'
Cursor   = require './cursor'
Stage    = require './stage'
Trans    = require './trans'
Browser  = require './browser'
Title    = require './title'

# post.debug()

class Kali

    constructor: (element) ->

        post.setMaxListeners 30
        
        Cursor.kali = @
        
        @element =$ element 
        @toolDiv = elem id: 'tools'
        @element.appendChild @toolDiv
        
        @toolSize     = 75
        @paletteWidth = 375
        
        @title   = new Title
        @trans   = new Trans @
        @tools   = new Tools @, name: 'tools', text: 'tools', orient: 'down'
        @stage   = new Stage @
        @browser = new Browser @
        
        @tools.init()
        
        @focus()
        # document.addEventListener 'keydown', @onKeyDown
        document.addEventListener 'keyup',   @onKeyUp
                
        window.onresize = @onResize
        
        @tools.loadPrefs()
        
        @title.tabs.restore()

        post.on 'menuAction', @onMenuAction
        post.on 'combo', @onCombo
        
    onResize: => 

        post.emit 'resize', pos sw(), sh()
                            
    closeStopPalette: ->
        
        if palette = @stopPalette
            delete @stopPalette
            palette.del()
        
    insertAboveSelection: (child) -> @element.insertBefore child, @stage.selection.element.nextSibling
    insertAboveStage: (child) -> @element.insertBefore child, @stage.element.nextSibling
    insertBelowTools: (child) -> @element.insertBefore child, @toolDiv
    insertAboveTools: (child) -> 
        @element.appendChild child
        child.style.zIndex = 1000
        
    shapeTool: -> @tools.getActive('shape')?.name
    
    tool: (name) -> @tools.getTool name 
    
    # 00     00  00000000  000   000  000   000      0000000    0000000  000000000  000   0000000   000   000
    # 000   000  000       0000  000  000   000     000   000  000          000     000  000   000  0000  000
    # 000000000  0000000   000 0 000  000   000     000000000  000          000     000  000   000  000 0 000
    # 000 0 000  000       000  0000  000   000     000   000  000          000     000  000   000  000  0000
    # 000   000  00000000  000   000   0000000      000   000   0000000     000     000   0000000   000   000
    
    onMenuAction: (name, args) =>
    
        # log "onMenuAction '#{name}'"
        
        switch name
    
            when 'Gradients'        then return post.emit 'tool', 'gradient'
            when 'Fonts'            then return post.emit 'tool', 'font'
            when 'Layers'           then return post.emit 'tool', 'layer'
            when 'Tools'            then return post.emit 'toggle', 'tools'
            
            when 'Close Tab'        then return @title.tabs.closeTab()
            when 'Close Others'     then return @title.tabs.closeOtherTabs()
            when 'Open Recent...'   then return post.emit 'browser', 'browseRecent'
            when 'Open...'          then return post.emit 'tool',    'open'
            when 'Open Dir...'      then return post.emit 'browser', 'openDir'
            
            when 'Save As...'       then return post.emit 'tool', 'saveAs'
            when 'Save'             then return post.emit 'tool', 'save'
            
            when 'Import...'        then return post.emit 'tool', 'import'
            when 'Export...'        then return post.emit 'tool', 'export'
            
            when 'Revert'           then return post.emit 'tool', 'load'
            when 'New'              then return post.emit 'tool', 'new'
            when 'Clear'            then return post.emit 'tool', 'clear'
            
            when 'Left'             then return post.emit 'tool', 'button', 'align', 'left'
            when 'Right'            then return post.emit 'tool', 'button', 'align', 'right'
            when 'Center'           then return post.emit 'tool', 'button', 'align', 'center'
            when 'Middle'           then return post.emit 'tool', 'button', 'align', 'mid'
            when 'Top'              then return post.emit 'tool', 'button', 'align', 'top'
            when 'Bottom'           then return post.emit 'tool', 'button', 'align', 'bot'
            
            when 'Convert Polygon'  then return post.emit 'convert', 'P'
            when 'Convert Line'     then return post.emit 'convert', 'L'
            when 'Convert Move'     then return post.emit 'convert', 'M'
            when 'Convert Quad'     then return post.emit 'convert', 'Q'
            when 'Convert Cubic'    then return post.emit 'convert', 'C'
            when 'Convert Smooth'   then return post.emit 'convert', 'S'
            when 'Convert Divide'   then return post.emit 'convert', 'D'
            
            when 'Front'            then return post.emit 'tool', 'button', 'send',  'front'
            when 'Raise'            then return post.emit 'tool', 'button', 'order', 'forward'
            when 'Lower'            then return post.emit 'tool', 'button', 'order', 'backward'
            when 'Back'             then return post.emit 'tool', 'button', 'send',  'back'
            
            when 'All'              then return post.emit 'tool', 'selectAll'
            when 'None'             then return post.emit 'tool', 'deselect'
            when 'Invert'           then return post.emit 'tool', 'invert'
            when 'Select Groups'    then return post.emit 'tool', 'selectGroups'
            
            when 'Horizontal'       then return post.emit 'tool', 'button', 'flip', 'horizontal'
            when 'Vertical'         then return post.emit 'tool', 'button', 'flip', 'vertical'
            
            when 'Lock'             then return post.emit 'tool', 'button', 'lock', 'lock'
            when 'Unlock'           then return post.emit 'tool', 'button', 'lock', 'unlock'
            
            when 'Group'            then return post.emit 'tool', 'group'
            when 'Ungroup'          then return post.emit 'tool', 'ungroup'
            
            when 'Cut'              then return post.emit 'tool', 'cut'
            when 'Copy'             then return post.emit 'tool', 'copy'
            when 'Paste'            then return post.emit 'tool', 'paste'
            
            when 'Undo'             then return post.emit 'tool', 'undo'
            when 'Redo'             then return post.emit 'tool', 'redo'
            
            when 'More'             then return post.emit 'tool', 'selectMore'
            when 'Less'             then return post.emit 'tool', 'selectLess'
            when 'Prev'             then return post.emit 'tool', 'selectPrev'
            when 'Next'             then return post.emit 'tool', 'selectNext'
            
            when 'Space Horizontal' then return post.emit 'tool', 'button', 'space', 'horizontal'
            when 'Space Vertical'   then return post.emit 'tool', 'button', 'space', 'vertical'
            when 'Space Radial'     then return post.emit 'tool', 'spaceRadial'
            when 'Average Radius'   then return post.emit 'tool', 'averageRadius'
            
            when 'Bezier'           then return post.emit 'tool', 'click', 'bezier_smooth'
            when 'Polygon'          then return post.emit 'tool', 'click', 'polygon'
            when 'Line'             then return post.emit 'tool', 'click', 'line'
            
            when 'Text'             then return post.emit 'tool', 'click', 'text'
            when 'Pick'             then return post.emit 'tool', 'click', 'pick'
            when 'Edit'             then return post.emit 'tool', 'click', 'edit'
            when 'Pan'              then return post.emit 'tool', 'click', 'pan'
            when 'Pipette'          then return post.emit 'tool', 'click', 'pipette'
            when 'Loupe'            then return post.emit 'tool', 'click', 'loupe'
            
            when 'Center Selection' then return post.emit 'tool', 'centerSelection'
            
            when 'Reset'            then return post.emit 'tool', 'button', 'zoom', 'reset'
            when 'Out'              then return post.emit 'tool', 'button', 'zoom', 'out'
            when 'In'               then return post.emit 'tool', 'button', 'zoom', 'in'
            when 'Grid'             then return post.emit 'tool', 'button', 'grid', 'grid'
            
            when 'Padding'          then return post.emit 'tool', 'button', 'padding', 'show'
            when 'Swap Fill/Stroke' then return post.emit 'tool', 'swapColor'
            when 'Properties'       then return post.emit 'tool', 'expandProperties'
            when 'All Tools'        then return post.emit 'tool', 'expandTools'
            when 'Groups'           then return post.emit 'tool', 'button', 'show', 'groups'
            when 'IDs'              then return post.emit 'tool', 'button', 'show', 'ids'
            when 'Wire'             then return post.emit 'tool', 'button', 'wire', 'wire'
            when 'Unwire'           then return post.emit 'tool', 'button', 'wire', 'unwire'
            
            when 'Previous Tab'     then return @title.tabs.navigate 'left'
            when 'Next Tab'         then return @title.tabs.navigate 'right'
            
        log "onMenuAction unhandled -- posting to main '#{name}' args: #{args}"
        
        post.toMain 'menuAction', name, args
                
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    focus: -> @element.focus()
    
    onCombo: (combo, info) =>
        
        if combo
            return stopEvent(event) if 'unhandled' != @browser.handleKey info.mod, info.key, info.combo, info.char, info.event, true

        return stopEvent(event) if 'unhandled' != @tools.handleKey info.mod, info.key, info.combo, info.char, info.event, true
        return stopEvent(event) if 'unhandled' != @stage.handleKey info.mod, info.key, info.combo, info.char, info.event, true
     
    onKeyUp: (event) =>
        
        {mod, key, combo, char} = keyinfo.forEvent event
        return stopEvent(event) if 'unhandled' != @tools.handleKey mod, key, combo, char, event, false
        return stopEvent(event) if 'unhandled' != @stage.handleKey mod, key, combo, char, event, false
                        
module.exports = Kali

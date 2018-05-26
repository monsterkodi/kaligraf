###
00     00  00000000  000   000  000   000
000   000  000       0000  000  000   000
000000000  0000000   000 0 000  000   000
000 0 000  000       000  0000  000   000
000   000  00000000  000   000   0000000
###

{ post, elem, sds, menu, log, $, _ } = require 'kxk'

pkg = require '../package'

class Menu

    @template: -> [

            # 000   000   0000000   000      000
            # 000  000   000   000  000      000
            # 0000000    000000000  000      000
            # 000  000   000   000  000      000
            # 000   000  000   000  0000000  000

            text: pkg.name
            menu: [
                text: "About",  accel: 'ctrl+,'
            ,
                text: ''
            ,
                text: 'Quit',   accel: 'ctrl+q'
            ]
        ,
            # 00000000  000  000      00000000
            # 000       000  000      000
            # 000000    000  000      0000000
            # 000       000  000      000
            # 000       000  0000000  00000000

            text: 'File'
            menu: [
                text: 'New',             accel: 'ctrl+n'
            ,
                text: 'Clear',           accel: 'ctrl+k'
            ,
                text: 'Revert',          accel: 'ctrl+r'
            ,
                text:  ''
            ,
                text: 'Open Recent...',  accel: 'ctrl+.'
            ,
                text: 'Open...',         accel: 'ctrl+o'
            ,
                text:  ''
            ,
                text: 'Save',            accel: 'ctrl+s'
            ,
                text: 'Save As...',      accel: 'ctrl+shift+s'
            ,
                text:  ''
            ,
                text: 'Import...',       accel: 'o'
            ,
                text: 'Export...',       accel: 'alt+ctrl+s'
            ]
        ,
            # 00000000  0000000    000  000000000
            # 000       000   000  000     000
            # 0000000   000   000  000     000
            # 000       000   000  000     000
            # 00000000  0000000    000     000

            text: 'Edit'
            menu: [
                text: 'Align'
                menu: [
                    text: 'Left',    accel: '1'
                ,
                    text: 'Right',   accel: 'ctrl+1'
                ,
                    text:  ''
                ,
                    text: 'Center',  accel: '2'
                ,
                    text: 'Middle',  accel: '3'
                ,
                    text: 'Join',    accel: 'j'
                ,
                    text:  ''
                ,
                    text: 'Top',     accel: '4'
                ,
                    text: 'Bottom',  accel: 'ctrl+4'
                ,
                    text:  ''
                ,
                    text: 'Space Horizontal', accel: '5'
                ,
                    text: 'Space Vertical',   accel: 'ctrl+5'
                ,
                    text:  ''
                ,
                    text: 'Space Radial',     accel: 'alt+6'
                ,
                    text: 'Average Radius',   accel: 'alt+ctrl+6'
                ]
            ,
                text: 'Bezier'
                menu: [
                    text: 'Convert Polygon', accel: 'alt+p'
                ,
                    text: 'Convert Line',    accel: 'alt+l'
                ,
                    text: 'Convert Move',    accel: 'alt+m'
                ,
                    text: 'Convert Quad',    accel: 'alt+q'
                ,
                    text: 'Convert Cubic',   accel: 'alt+c'
                ,
                    text: 'Convert Smooth',  accel: 'alt+s'
                ,
                    text: 'Convert Divide',  accel: 'alt+d'
                ]
            ,
                text: 'Order'
                menu: [
                    text: 'Front',       accel: 'alt+ctrl+up'
                ,
                    text: 'Raise',       accel: 'ctrl+up'
                ,
                    text: 'Lower',       accel: 'ctrl+down'
                ,
                    text: 'Back',        accel: 'alt+ctrl+down'
                ]
            ,
                text: 'Select'
                menu: [
                    text: 'All',         accel: 'ctrl+a'
                ,
                    text: 'None',        accel: 'ctrl+d'
                ,
                    text: 'Invert',      accel: 'ctrl+i'
                ,
                    text:  ''
                ,
                    text: 'More',        accel: 'ctrl+m'
                ,
                    text: 'Less',        accel: 'ctrl+shift+m'
                ,
                    text: 'Prev',        accel: 'ctrl+['
                ,
                    text: 'Next',        accel: 'ctrl+]'
                ]
            ,
                text: 'Flip'
                menu: [
                    text: 'Horizontal',  accel: '6'
                ,
                    text: 'Vertical',    accel: 'ctrl+6'
                ]
            ,
                text:  ''
            ,
                text: 'Lock',        accel: 'k'
            ,
                text: 'Unlock',      accel: ';'
            ,
                text:  ''
            ,
                text: 'Group',       accel: 'ctrl+g'
            ,
                text: 'Ungroup',     accel: 'ctrl+u'
            ,
                text:  ''
            ,
                text: 'Cut',         accel: 'ctrl+x'
            ,
                text: 'Copy',        accel: 'ctrl+c'
            ,
                text: 'Paste',       accel: 'ctrl+v'
            ,
                text:  ''
            ,
                text: 'Undo',        accel: 'ctrl+z'
            ,
                text: 'Redo',        accel: 'ctrl+shift+z'
            ]
        ,
            # 000000000   0000000    0000000   000
            #    000     000   000  000   000  000
            #    000     000   000  000   000  000
            #    000     000   000  000   000  000
            #    000      0000000    0000000   0000000

            text: 'Tool'
            menu: [

                text: 'Zoom'
                menu: [
                    text: 'Center Selection', accel: 'ctrl+e'
                ,
                    text:'Reset',    accel: 'ctrl+0'
                ,
                    text:'Out',      accel: 'ctrl+-'
                ,
                    text:'In',       accel: 'ctrl+='
                ]
            ,
                text: 'Toggle'
                menu: [
                    text: 'Padding',     accel: 'p'
                ,
                    text: 'Fill/Stroke', accel: 'ctrl+7'
                ,
                    text: 'Grid',        accel: 'ctrl+9'
                ,
                    text: 'Properties',  accel: 'ctrl+;'
                ,
                    text: 'Tools',       accel: 'ctrl+shift+t'
                ,
                    text: 'Groups',      accel: 'ctrl+shift+g'
                ,
                    text: 'IDs',         accel: 'ctrl+shift+i'
                ,
                    text: 'Wire',        accel: 'w'
                ,
                    text: 'Unwire',      accel: 'ctrl+w'
                ]
            ,
                text:  ''
            ,
                text: 'Bezier',      accel: 'ctrl+b'
            ,
                text: 'Polygon',     accel: 'ctrl+p'
            ,
                text: 'Line',        accel: 'ctrl+/'
            ,
                text: 'Text',        accel: 'ctrl+t'
            ]
        ,
            # 000   000  000  00000000  000   000
            # 000   000  000  000       000 0 000
            #  000 000   000  0000000   000000000
            #    000     000  000       000   000
            #     0      000  00000000  00     00

            text: 'View'
            menu: [
                text: 'Layers',      accel: 'ctrl+l'
            ,
                text: 'Fonts',       accel: 'ctrl+f'
            ,
                text: 'Gradients',   accel: 'ctrl+j'
            ]
        ,
            # 000   000  000  000   000  0000000     0000000   000   000
            # 000 0 000  000  0000  000  000   000  000   000  000 0 000
            # 000000000  000  000 0 000  000   000  000   000  000000000
            # 000   000  000  000  0000  000   000  000   000  000   000
            # 00     00  000  000   000  0000000     0000000   00     00

            text: 'Window'
            menu: [
                text: 'Minimize',   accel: 'alt+ctrl+shift+m'
            ,
                text: 'Maximize',   accel: 'alt+ctrl+m'
            ,
                text: ''
            ,
                text: 'Toggle Menu', accel:  'alt+m' 
            ,
                text: ''
            ,
                text: 'Reload',     accel: 'alt+ctrl+l'
            ,
                text: 'DevTools',   accel: 'alt+ctrl+i'
            ]
        ]

    constructor: ->

        @menu = new menu items:Menu.template()
        @elem = @menu.elem
        window.title.elem.insertBefore @elem, window.title.elem.firstChild.nextSibling
        @hide()

    visible: => @elem.style.display != 'none'
    show:    => @elem.style.display = 'inline-block'; @menu?.focus?(); post.emit 'titlebar', 'hideTitle'
    hide:    => @menu?.close(); @elem.style.display = 'none'; post.emit 'titlebar', 'showTitle'
    toggle:  => if @visible() then @hide() else @show()

    # 000   000  00000000  000   000
    # 000  000   000        000 000
    # 0000000    0000000     00000
    # 000  000   000          000
    # 000   000  00000000     000

    globalModKeyComboEvent: (mod, key, combo, event) ->

        # log 'globalModKeyComboEvent', mod, key, combo
        
        if not @mainMenu
            @mainMenu = Menu.template()

        for keypath in sds.find.key @mainMenu, 'accel'
            if combo == sds.get @mainMenu, keypath
                keypath.pop()
                item = sds.get @mainMenu, keypath
                # log 'key action!', item.action ? item.text, item.actarg
                post.emit 'menuAction', item.action ? item.text, item.actarg
                return item

        'unhandled'

module.exports = Menu

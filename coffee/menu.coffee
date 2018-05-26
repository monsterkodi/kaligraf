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
                text: "About #{pkg.name}",   accel: 'command+,'
            ,
                text: ''
            ,
                text: 'Quit',                accel: 'command+q'
            ]
        ,
            # 00000000  000  000      00000000
            # 000       000  000      000
            # 000000    000  000      0000000
            # 000       000  000      000
            # 000       000  0000000  00000000

            text: 'File'
            menu: [
                text: 'New',             accel: 'command+n'
            ,
                text: 'Clear',           accel: 'command+k'
            ,
                text: 'Reload',          accel: 'command+r'
            ,
                text:  ''
            ,
                text: 'Open Recent...',  accel: 'command+.'
            ,
                text: 'Open...',         accel: 'command+o'
            ,
                text:  ''
            ,
                text: 'Save',            accel: 'command+s'
            ,
                text: 'Save As...',      accel: 'command+shift+s'
            ,
                text:  ''
            ,
                text: 'Import...',       accel: 'o'
            ,
                text: 'Export...',       accel: 'command+alt+s'
            ,
                text:  ''
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
                    text: 'Right',   accel: 'command+1'
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
                    text: 'Bottom',  accel: 'command+4'
                ,
                    text:  ''
                ,
                    text: 'Space Horizontal', accel: '5'
                ,
                    text: 'Space Vertical',   accel: 'command+5'
                ,
                    text:  ''
                ,
                    text: 'Space Radial',     accel: '6'
                ,
                    text: 'Average Radius',   accel: 'command+6'
                ]
            ,
                text: 'Bezier'
                menu: [
                    text: 'Polygon', accel: 'ctrl+p'
                ,
                    text: 'Line',    accel: 'ctrl+l'
                ,
                    text: 'Move',    accel: 'ctrl+m'
                ,
                    text: 'Quad',    accel: 'ctrl+q'
                ,
                    text: 'Cubic',   accel: 'ctrl+c'
                ,
                    text: 'Smooth',  accel: 'ctrl+s'
                ,
                    text: 'Divide',  accel: 'ctrl+d'
                ]
            ,
                text: 'Order'
                menu: [
                    text: 'Front',       accel: 'command+alt+up'
                ,
                    text: 'Raise',       accel: 'command+up'
                ,
                    text: 'Lower',       accel: 'command+down'
                ,
                    text: 'Back',        accel: 'command+alt+down'
                ]
            ,
                text: 'Select'
                menu: [
                    text: 'All',         accel: 'command+a'
                ,
                    text: 'None',        accel: 'command+d'
                ,
                    text: 'Invert',      accel: 'command+i'
                ,
                    text:  ''
                ,
                    text: 'More',        accel: 'command+m'
                ,
                    text: 'Less',        accel: 'command+shift+m'
                ,
                    text: 'Prev',        accel: 'command+['
                ,
                    text: 'Next',        accel: 'command+]'
                ]
            ,
                text: 'Flip'
                menu: [
                    text: 'Horizontal',  accel: '6'
                ,
                    text: 'Vertical',    accel: 'command+6'
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
                text: 'Group',       accel: 'command+g'
            ,
                text: 'Ungroup',     accel: 'command+u'
            ,
                text:  ''
            ,
                text: 'Cut',         accel: 'command+x'
            ,
                text: 'Copy',        accel: 'command+c'
            ,
                text: 'Paste',       accel: 'command+v'
            ,
                text:  ''
            ,
                text: 'Undo',        accel: 'command+z'
            ,
                text: 'Redo',        accel: 'command+shift+z'
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
                    text:'Reset',    accel: 'command+0'
                ,
                    text:'Out',      accel: 'command+-'
                ,
                    text:'In',       accel: 'command+='
                ]
            ,
                text: 'Toggle'
                menu: [
                    text: 'Padding',     accel: 'p'
                ,
                    text: 'Fill/Stroke', accel: 'command+7'
                ,
                    text: 'Properties',  accel: 'command+t'
                ,
                    text: 'Tools',       accel: 'command+shift+t'
                ,
                    text: 'Groups',      accel: 'command+shift+g'
                ,
                    text: 'IDs',         accel: 'command+shift+i'
                ,
                    text: 'Wire',        accel: 'w'
                ,
                    text: 'Unwire',      accel: 'command+w'
                ]
            ,
                text:  ''
            ,
                text: 'Bezier',      accel: 'command+b'
            ,
                text: 'Polygon',     accel: 'command+p'
            ,
                text: 'Line',        accel: 'command+/'
            ,
                text: 'Text',        accel: 'command+t'
            ,
                text:  ''
            ,
                text: 'Grid',        accel: 'command+9'
            ,
                text: 'Center',      accel: 'command+e'
            ]
        ,
            # 000   000  000  00000000  000   000
            # 000   000  000  000       000 0 000
            #  000 000   000  0000000   000000000
            #    000     000  000       000   000
            #     0      000  00000000  00     00

            text: 'View'
            menu: [
                text: 'Layers',      accel: 'command+l'
            ,
                text: 'Fonts',       accel: 'command+f'
            ,
                text: 'Gradients',   accel: 'command+j'
            ]
        ,
            # 000   000  000  000   000  0000000     0000000   000   000
            # 000 0 000  000  0000  000  000   000  000   000  000 0 000
            # 000000000  000  000 0 000  000   000  000   000  000000000
            # 000   000  000  000  0000  000   000  000   000  000   000
            # 00     00  000  000   000  0000000     0000000   00     00

            text: 'Window'
            menu: [
                text: 'Minimize',   accel: 'command+alt+shift+m'
            ,
                text: 'Maximize',   accel: 'command+alt+m'
            ,
                text:  ''
            ,
                text: 'Reload',     accel: 'Ctrl+Alt+L'
            ,
                text: 'DevTools',   accel: 'Ctrl+Alt+I'
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

        if not @mainMenu
            @mainMenu = Menu.template()

        for keypath in sds.find.key @mainMenu, 'accel'
            if combo == sds.get @mainMenu, keypath
                keypath.pop()
                item = sds.get @mainMenu, keypath
                post.emit 'menuAction', item.action ? item.text, item.actarg
                return item

        'unhandled'

module.exports = Menu

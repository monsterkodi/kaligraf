###
00     00  00000000  000   000  000   000
000   000  000       0000  000  000   000
000000000  0000000   000 0 000  000   000
000 0 000  000       000  0000  000   000
000   000  00000000  000   000   0000000
###

{ post, elem, sds, menu, empty, slash, noon, str, log, $, _ } = require 'kxk'

pkg = require '../package'

class Menu

    @template: ->
        
        if empty Menu.templateCache
            Menu.templateCache = Menu.makeTemplate noon.load slash.join __dirname, 'menu.noon'
        Menu.templateCache
        
    @makeTemplate: (obj) ->
        
        tmpl = []
        for text,menuOrAccel of obj
            tmpl.push switch
                when empty(menuOrAccel) and text.startsWith '-'
                    text: ''
                when _.isNumber menuOrAccel
                    text:text
                    accel:str menuOrAccel
                when _.isString menuOrAccel
                    text:text
                    accel:menuOrAccel
                when empty(menuOrAccel)
                    text:text
                    accel: ''
                else
                    text:text
                    menu:@makeTemplate menuOrAccel
        tmpl

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
            combos = sds.get(@mainMenu, keypath).split ' '
            if combo in combos
                keypath.pop()
                item = sds.get @mainMenu, keypath
                post.emit 'menuAction', item.action ? item.text, item.actarg
                return item

        'unhandled'

module.exports = Menu

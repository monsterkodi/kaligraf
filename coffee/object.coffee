
#  0000000   0000000          000  00000000   0000000  000000000
# 000   000  000   000        000  000       000          000
# 000   000  0000000          000  0000000   000          000
# 000   000  000   000  000   000  000       000          000
#  0000000   0000000     0000000   00000000   0000000     000

{ pos, log, _ } = require 'kxk'

Ctrl = require './ctrl'

class Object

    constructor: (@edit, item) ->

        @svg   = @edit.svg
        @kali  = @edit.kali
        @trans = @kali.trans

        @ctrls = []

        if item? then @setItem item

    # 0000000    00000000  000
    # 000   000  000       000
    # 000   000  0000000   000
    # 000   000  000       000
    # 0000000    00000000  0000000

    del: ->

        for ctrl in @ctrls
            ctrl.del()

        @ctrls = []

    #  0000000  00000000  000000000     000  000000000  00000000  00     00
    # 000       000          000        000     000     000       000   000
    # 0000000   0000000      000        000     000     0000000   000000000
    #      000  000          000        000     000     000       000 0 000
    # 0000000   00000000     000        000     000     00000000  000   000

    setItem: (item) ->

        @del()

        @item = item

        points = @item.array().valueOf()
        isPath = @isPath()

        for i in [0...points.length]

            point = points[i]

            if isPath
                p = pos point[point.length-2], point[point.length-1]
            else
                p = pos point[0], point[1]

            @editCtrl 'append', 'point', i, @trans.transform @item, p

            if isPath

                switch point[0]
                    when 'C', 'c', 'S', 's', 'Q', 'q'
                        @editCtrl 'append', 'ctrl1', i, @trans.transform @item, pos point[1], point[2]

                switch point[0]
                    when 'S', 's'
                        @editCtrl 'append', 'ctrlr', i, @reflPos i, 'ctrlr'
                        
                    when 'C', 'c'
                        @editCtrl 'append', 'ctrl2', i, @trans.transform @item, pos point[3], point[4]

    # 00000000  0000000    000  000000000
    # 000       000   000  000     000
    # 0000000   000   000  000     000
    # 000       000   000  000     000
    # 00000000  0000000    000     000

    editCtrl: (action, type, index, stagePos) =>

        switch action

            when 'append'

                if index < @ctrls.length
                    ctrl = @ctrls[index]
                else
                    ctrl = new Ctrl @
                    @ctrls.push ctrl

                ctrl.createDot type

            when 'change'

                ctrl = @ctrls[index]
                
            when 'delete'
                
                ctrl = @ctrls[index]
                _.pull @ctrls, ctrl
                ctrl.del()
                return

        if not ctrl?
            log "no ctrl? item:#{@item.id()} action: #{action} type:#{type} index:#{index}"
        else
            ctrl.setPos type, stagePos

    # 00     00   0000000   000   000  00000000
    # 000   000  000   000  000   000  000
    # 000000000  000   000   000 000   0000000
    # 000 0 000  000   000     000     000
    # 000   000   0000000       0      00000000

    moveBy: (delta) ->

        for ctrl in @ctrls
            ctrl.moveBy delta

        @plot()

    # 000   000  00000000   0000000     0000000   000000000  00000000
    # 000   000  000   000  000   000  000   000     000     000
    # 000   000  00000000   000   000  000000000     000     0000000
    # 000   000  000        000   000  000   000     000     000
    #  0000000   000        0000000    000   000     000     00000000

    updatePos: ->

        for ctrl in @ctrls
            ctrl.updatePos()

    # 00000000   000       0000000   000000000
    # 000   000  000      000   000     000
    # 00000000   000      000   000     000
    # 000        000      000   000     000
    # 000        0000000   0000000      000

    plot: -> @item.plot @item.array()

    # 00000000   00000000  00000000  000
    # 000   000  000       000       000
    # 0000000    0000000   000000    000
    # 000   000  000       000       000
    # 000   000  00000000  000       0000000

    reflPos: (index, type) ->

        pp = @getPos index, 'point'
        cp = @getPos index, type == 'ctrl1' and 'ctrlr' or 'ctrl1'
        if pp? and cp?
            pp.plus pp.minus cp

    getPos: (index, type='point') -> @ctrls[index]?.getPos type

    points: -> @item.array().valueOf()

    isPoly: -> @item.type in ['polygon', 'polyline', 'line']
    isPath: -> not @isPoly()

module.exports = Object

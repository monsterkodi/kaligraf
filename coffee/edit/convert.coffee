###
 0000000   0000000   000   000  000   000  00000000  00000000   000000000
000       000   000  0000  000  000   000  000       000   000     000   
000       000   000  000 0 000   000 000   0000000   0000000       000   
000       000   000  000  0000     000     000       000   000     000   
 0000000   0000000   000   000      0      00000000  000   000     000   
###

{ pos, log, _ } = require 'kxk'

Ctrl = require './ctrl'

class Convert
            
    convert: (dots, type) ->

        if type == 'D' then return @divide dots

        newDots = []

        points = @points()

        indexDots = @indexDots dots

        for idots in indexDots

            index = idots.index
            point = points[index]

            continue if index == 0

            thisp = @posAt index
            prevp = @posAt index-1

            switch type

                when 'C'

                    switch point[0]
                        when 'C'
                            newDots = newDots.concat _.values @ctrls[index].dots
                            continue
                        when 'Q'
                            ctrl = pos point[1], point[2]
                            mid1 = prevp.plus (prevp.to ctrl).times 2/3
                            mid2 = thisp.plus (thisp.to ctrl).times 2/3
                            point.splice 1, 2, mid1.x, mid1.y, mid2.x, mid2.y
                        when 'S'
                            ctrls = @posAt index, 'ctrls'
                            ctrlr = @posAt index, 'ctrlr'
                            point.splice 1, 2, ctrlr.x, ctrlr.y, ctrls.x, ctrls.y
                        when 'M', 'L'
                            mid1 = prevp.plus (prevp.to thisp).times 1/3
                            mid2 = prevp.plus (prevp.to thisp).times 2/3
                            point.splice 1, 0, mid1.x, mid1.y, mid2.x, mid2.y

                    point[0] = 'C'

                when 'Q'

                    switch point[0]
                        when 'Q'
                            newDots = newDots.concat _.values @ctrls[index].dots
                            continue
                        when 'C'
                            ext1 = prevp.plus (prevp.to @posAt index, 'ctrl1').times 3/2
                            ext2 = thisp.plus (thisp.to @posAt index, 'ctrl2').times 3/2
                            midp = ext1.mid ext2
                            point.splice 1, 4, midp.x, midp.y
                        when 'M', 'L'
                            midp = prevp.mid thisp
                            point.splice 1, 0, midp.x, midp.y

                    point[0] = 'Q'

                when 'S'

                    switch point[0]
                        when 'S'
                            newDots = newDots.concat _.values @ctrls[index].dots
                            continue
                        when 'C'
                            point.splice 1, 2
                        when 'M', 'L'
                            midp = prevp.mid thisp
                            point.splice 1, 0, midp.x, midp.y

                    point[0] = 'S'
                    
                when 'P'
                    
                    point[0] = point[point.length-2]
                    point[1] = point[point.length-1]
                    point.splice 2, point.length-2

            @initCtrlDots   index, point
            @updateCtrlDots index, point

            newDots = newDots.concat _.values @ctrls[index].dots

        @plot()
        newDots

    # 0000000    000  000   000  000  0000000    00000000
    # 000   000  000  000   000  000  000   000  000
    # 000   000  000   000 000   000  000   000  0000000
    # 000   000  000     000     000  000   000  000
    # 0000000    000      0      000  0000000    00000000

    divide: (dots) ->

        newDots = []

        points = @points()

        indexDots = @indexDots dots

        for idots in indexDots

            index = idots.index
            point = points[index]

            continue if index == 0 and _.isString point[0]

            previ = index-1
            previ = @numPoints()-1 if index < 0
            thisp = @posAt index
            prevp = @posAt previ

            switch point[0]

                when 'C'

                    newPoint = @deCasteljau index, point                    

                when 'Q', 'S'

                    ctrl  = pos point[1], point[2]
                    ctrl1 = prevp.mid ctrl
                    ctrl2 = thisp.mid ctrl
                    mid = ctrl1.mid ctrl2

                    newPoint = [point[0], ctrl2.x, ctrl2.y, point[3], point[4]]

                    point[1] = ctrl1.x
                    point[2] = ctrl1.y
                    point[3] = mid.x
                    point[4] = mid.y

                when 'M', 'L'

                    newPoint = [point[0], point[1], point[2]]

                    mid = prevp.mid thisp
                    point[1] = mid.x
                    point[2] = mid.y
                    
                else
                    
                    newPoint = [point[0], point[1]]
                    mid = prevp.mid thisp
                    point[0] = mid.x
                    point[1] = mid.y

            @initCtrlDots   index, point
            @updateCtrlDots index, point

            newDots = newDots.concat _.values @ctrls[index].dots

            points.splice index+1, 0, newPoint
            @ctrls.splice index+1, 0, new Ctrl @

            @initCtrlDots   index+1, newPoint
            @updateCtrlDots index+1, newPoint

            newDots = newDots.concat _.values @ctrls[index+1].dots

        @plot()
        newDots

    #  0000000   0000000    0000000  000000000  00000000  000            000   0000000   000   000  
    # 000       000   000  000          000     000       000            000  000   000  000   000  
    # 000       000000000  0000000      000     0000000   000            000  000000000  000   000  
    # 000       000   000       000     000     000       000      000   000  000   000  000   000  
    #  0000000  000   000  0000000      000     00000000  0000000   0000000   000   000   0000000   
    
    deCasteljau: (index, point) ->
        
        thisp = @posAt index
        prevp = @posAt index-1
        
        ctrl1 = @posAt index, 'ctrl1'
        ctrl2 = @posAt index, 'ctrl2'

        p23 = ctrl1.mid ctrl2
        p12 = prevp.mid ctrl1
        p34 = thisp.mid ctrl2
        
        p123  = p12.mid p23
        p234  = p23.mid p34
        p1234 = p123.mid p234
        
        point[1] = p12.x
        point[2] = p12.y
        point[3] = p123.x
        point[4] = p123.y
        point[5] = p1234.x
        point[6] = p1234.y
        
        ['C', p234.x, p234.y, p34.x, p34.y, thisp.x, thisp.y]
        
module.exports = Convert

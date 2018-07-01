###
00000000   00000000    0000000   00000000  000  000      00000000
000   000  000   000  000   000  000       000  000      000     
00000000   0000000    000   000  000000    000  000      0000000 
000        000   000  000   000  000       000  000      000     
000        000   000   0000000   000       000  0000000  00000000
###

{ valid, log } = require 'kxk'

now = require 'performance-now'

tags = {}

profile = (msg) ->

    if profile.start? and valid profile.s_msg
        ms = (now()-profile.start).toFixed 0
        if ms > 1000
            log "#{profile.s_msg} in #{(ms/1000).toFixed(3)} sec"
        else
            log "#{profile.s_msg} in #{ms} ms"

    profile.start = now()
    profile.s_msg = msg

profile.now   = now
profile.start = undefined
profile.s_msg = undefined

profile.tag   = (name) -> tags[name] = now()
profile.delta = (name) -> (now() - (tags[name] ? profile.start)).toFixed 0

module.exports = profile

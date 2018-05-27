###
000000000  000  000000000  000      00000000
   000     000     000     000      000     
   000     000     000     000      0000000 
   000     000     000     000      000     
   000     000     000     0000000  00000000
###

{ elem, slash, post, log, $ } = require 'kxk'

pkg  = require '../package.json'
Tabs = require './tabs'

class Title
    
    constructor: () ->

        post.on 'titlebar', @onTitlebar
        
        @elem =$ "#titlebar"
        @elem.ondblclick = (event) -> post.toMain 'maximizeWindow', window.winID
                
        @winicon = elem class: 'winicon'
        @winicon.appendChild elem 'img', src:slash.fileUrl __dirname + '/../img/menu@2x.png'
        @elem.appendChild @winicon
        @winicon.addEventListener 'click', -> post.emit 'menuAction', 'Toggle Menu'   
        
        @title = elem class: 'titlebar-title'
        html  = "<span class='titlebar-name'>kali</span>"
        html += "<span class='titlebar-dot'> ● </span>"
        html += "<span class='titlebar-version'>#{pkg.version}</span>"
        @title.innerHTML = html
        @title.ondblclick = => post.toMain 'toggleMaximize'
        @elem.appendChild @title
        
        @tabs = new Tabs @elem
        
        @minimize = elem class: 'winclose gray'
        @elem.appendChild @minimize
        @minimize.appendChild elem 'img', src:slash.fileUrl __dirname + '/../img/minimize.png'
        @minimize.addEventListener 'click', -> post.emit 'menuAction', 'Minimize'
        
        @maximize = elem class: 'winclose gray'
        @elem.appendChild @maximize
        @maximize.appendChild elem 'img', src:slash.fileUrl __dirname + '/../img/maximize.png'
        @maximize.addEventListener 'click', -> post.emit 'menuAction', 'Maximize'

        @close = elem class: 'winclose'
        @elem.appendChild @close
        @close.appendChild elem 'img', src:slash.fileUrl __dirname + '/../img/close.png'
        @close.addEventListener 'click', -> post.emit 'menuAction', 'Close Window'
         
    showTitle: -> @title.style.display = 'initial'
    hideTitle: -> @title.style.display = 'none'
        
    swapForTabs: (swapIn) -> 
        @tabs.div.parentNode.insertBefore swapIn, @tabs.div
        @tabs.div.style.display = 'none'
        
    restoreTabs: ->
        @tabs.div.previousSibling.remove()
        @tabs.div.style.display = ''
    
    onTitlebar: (action) =>
        
        switch action
            when 'showTitle' then @showTitle()
            when 'hideTitle' then @hideTitle()
        
module.exports = Title

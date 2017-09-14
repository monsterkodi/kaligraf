# 00     00   0000000   000  000   000  00     00  00000000  000   000  000   000
# 000   000  000   000  000  0000  000  000   000  000       0000  000  000   000
# 000000000  000000000  000  000 0 000  000000000  0000000   000 0 000  000   000
# 000 0 000  000   000  000  000  0000  000 0 000  000       000  0000  000   000
# 000   000  000   000  000  000   000  000   000  00000000  000   000   0000000 

{ post, log }  = require 'kxk'

pkg      = require '../package.json'
electron = require 'electron'
Menu     = electron.Menu

action = (action) -> post.toWins 'tool', action

class MainMenu
    
    @init: (app) -> 
        
        Menu.setApplicationMenu Menu.buildFromTemplate [
            
            # 000   000   0000000   000      000  
            # 000  000   000   000  000      000  
            # 0000000    000000000  000      000  
            # 000  000   000   000  000      000  
            # 000   000  000   000  0000000  000  
            
            label: pkg.name, submenu: [     
                { label: "About #{pkg.name}",   accelerator: 'Cmd+.',       click: app.showAbout}
                { type:  'separator'}
                { label: "Hide #{pkg.name}",    accelerator: 'Cmd+H',       role: 'hide'}
                { label: 'Hide Others',         accelerator: 'Cmd+Alt+H',   role: 'hideothers'}
                { type:  'separator'}
                { label: 'Quit',                accelerator: 'Cmd+Q',       click: app.quit}
            ]
        ,
            label: 'File', submenu: [
                { label: 'Save',        accelerator: 'command+s',           click: -> action 'save'}
                { label: 'Open...',     accelerator: 'command+o',           click: -> action 'load'}
                { label: 'Reload',      accelerator: 'command+r',           click: -> action 'load'}
                { label: 'Clear',       accelerator: 'command+k',           click: -> action 'clear'}
            ]
        ,
            label: 'Edit', submenu: [
                { label: 'Cut',         accelerator: 'command+x',           click: -> action 'cut'}
                { label: 'Copy',        accelerator: 'command+c',           click: -> action 'copy'}
                { label: 'Paste',       accelerator: 'command+v',           click: -> action 'paste'}
                { type:  'separator'}
                { label: 'Front',       accelerator: 'command+alt+up',      click: -> action 'front'}
                { label: 'Raise',       accelerator: 'command+up',          click: -> action 'raise'}
                { label: 'Lower',       accelerator: 'command+down',        click: -> action 'lower'}
                { label: 'Back',        accelerator: 'command+alt+down',    click: -> action 'back' }
                { type:  'separator'}
                { label: 'Center',      accelerator: 'command+e',           click: -> action 'center'}
                { label: 'All',         accelerator: 'command+a',           click: -> action 'selectAll'}
                { label: 'None',        accelerator: 'command+d',           click: -> action 'deselect'}
                { label: 'Invert',      accelerator: 'command+i',           click: -> action 'invert'}        
            ]
        ,
            # 000   000  000  000   000  0000000     0000000   000   000
            # 000 0 000  000  0000  000  000   000  000   000  000 0 000
            # 000000000  000  000 0 000  000   000  000   000  000000000
            # 000   000  000  000  0000  000   000  000   000  000   000
            # 00     00  000  000   000  0000000     0000000   00     00
            
            label: 'Window', submenu: [
                { label: 'Minimize',           accelerator: 'Alt+Cmd+M',        click: (i,win) -> win?.minimize()}
                { label: 'Maximize',           accelerator: 'Cmd+Shift+m',      click: (i,win) -> app.toggleMaximize win}
                { type:  'separator'}
                { label: 'Bring All to Front', accelerator: 'Alt+Cmd+`',        role: 'front'}
                { type:  'separator'}
                { label: 'Reload Window',      accelerator: 'Ctrl+Alt+Cmd+L',   click: (i,win) -> app.reloadWin win}
                { label: 'Toggle DevTools',    accelerator: 'Cmd+Alt+I',        click: (i,win) -> win?.webContents.openDevTools()}
            ]
        ,        
            # 000   000  00000000  000      00000000 
            # 000   000  000       000      000   000
            # 000000000  0000000   000      00000000 
            # 000   000  000       000      000      
            # 000   000  00000000  0000000  000      
            
            label: 'Help', role: 'help', submenu: []            
        ]

module.exports = MainMenu

# 00     00  00000000  000   000  000   000
# 000   000  000       0000  000  000   000
# 000000000  0000000   000 0 000  000   000
# 000 0 000  000       000  0000  000   000
# 000   000  00000000  000   000   0000000 

{ post, log }  = require 'kxk'

pkg      = require '../package.json'
electron = require 'electron'

action = (action, arg) -> post.toWins 'tool', action, arg

class Menu
    
    @init: (app) -> 
        
        electron.Menu.setApplicationMenu electron.Menu.buildFromTemplate [
            
            # 000   000   0000000   000      000  
            # 000  000   000   000  000      000  
            # 0000000    000000000  000      000  
            # 000  000   000   000  000      000  
            # 000   000  000   000  0000000  000  
            
            label: pkg.name, submenu: [     
                { label: "About #{pkg.name}",   accelerator: 'command+/',       click: app.showAbout}
                { type:  'separator'}
                { label: "Hide #{pkg.name}",    accelerator: 'command+h',       role: 'hide'}
                { label: 'Hide Others',         accelerator: 'command+alt+h',   role: 'hideothers'}
                { type:  'separator'}
                { label: 'Quit',                accelerator: 'command+q',       click: app.quit}
            ]
        ,
            # 00000000  000  000      00000000  
            # 000       000  000      000       
            # 000000    000  000      0000000   
            # 000       000  000      000       
            # 000       000  0000000  00000000  
            
            label: 'File', submenu: [
                { label: 'Open Recent...',  accelerator: 'command+.',       click: -> action 'browse'}
                { label: 'Open...',         accelerator: 'command+o',       click: -> action 'open'}
                { type:  'separator'}
                { label: 'Save',            accelerator: 'command+s',       click: -> action 'save'}
                { label: 'Save As...',      accelerator: 'command+shift+s', click: -> action 'saveAs'}
                { type:  'separator'}    
                { label: 'Clear',           accelerator: 'command+k',       click: -> action 'clear'}
                { label: 'Reload',          accelerator: 'command+r',       click: -> action 'load'}
            ]
        ,
            # 00000000  0000000    000  000000000  
            # 000       000   000  000     000     
            # 0000000   000   000  000     000     
            # 000       000   000  000     000     
            # 00000000  0000000    000     000     
            
            label: 'Edit', submenu: [
                { label: 'Convert',     submenu: [
                    { label: 'Quad',    accelerator: 'command+1',           click: -> post.toWins 'convert', 'Q'}
                    { label: 'Cubic',   accelerator: 'command+2',           click: -> post.toWins 'convert', 'C'}
                    { label: 'Smooth',  accelerator: 'command+3',           click: -> post.toWins 'convert', 'S'}
                    { label: 'Divide',  accelerator: 'command+4',           click: -> post.toWins 'convert', 'D'}
                ]}
                { label: 'Align',     submenu: [
                    { label: 'Left',    accelerator: 'alt+1',               click: -> post.toWins 'align', 'left'}
                    { label: 'Center',  accelerator: 'alt+2',               click: -> post.toWins 'align', 'center'}
                    { label: 'Right',   accelerator: 'alt+3',               click: -> post.toWins 'align', 'right'}
                    { type:  'separator'}
                    { label: 'Top',     accelerator: 'alt+4',               click: -> post.toWins 'align', 'top'}
                    { label: 'Middle',  accelerator: 'alt+5',               click: -> post.toWins 'align', 'mid'}
                    { label: 'Bottom',  accelerator: 'alt+6',               click: -> post.toWins 'align', 'bot'}
                    { type:  'separator'}
                    { label: 'Space Horizontal', accelerator: 'alt+7',      click: -> post.toWins 'space', 'horizontal'}
                    { label: 'Space Vertical',   accelerator: 'alt+8',      click: -> post.toWins 'space', 'vertical'}
                ]}                
                { type:  'separator'}
                { label: 'Group',       accelerator: 'command+g',           click: -> action 'group'}
                { label: 'Ungroup',     accelerator: 'command+u',           click: -> action 'ungroup'}
                { type:  'separator'}
                { label: 'Front',       accelerator: 'command+alt+up',      click: -> action 'front'}
                { label: 'Raise',       accelerator: 'command+up',          click: -> action 'raise'}
                { label: 'Lower',       accelerator: 'command+down',        click: -> action 'lower'}
                { label: 'Back',        accelerator: 'command+alt+down',    click: -> action 'back' }
                { type:  'separator'}
                { label: 'Cut',         accelerator: 'command+x',           click: -> action 'cut'}
                { label: 'Copy',        accelerator: 'command+c',           click: -> action 'copy'}
                { label: 'Paste',       accelerator: 'command+v',           click: -> action 'paste'}
                { type:  'separator'}
                { label: 'All',         accelerator: 'command+a',           click: -> action 'selectAll'}
                { label: 'None',        accelerator: 'command+d',           click: -> action 'deselect'}
                { label: 'Invert',      accelerator: 'command+i',           click: -> action 'invert'}        
            ]
        ,
            # 000000000   0000000    0000000   000      
            #    000     000   000  000   000  000      
            #    000     000   000  000   000  000      
            #    000     000   000  000   000  000      
            #    000      0000000    0000000   0000000  
            
            label: 'Tool', submenu: [
                { label: 'Text',        accelerator: 'command+t',           click: -> action 'click', 'text'}
                { label: 'Font',        accelerator: 'command+f',           click: -> action 'click', 'font'}
                { type:  'separator'}
                { label: 'Color',       submenu: [
                    { label: 'Swap Fill Stroke', click: -> action 'swapColor'}
                ] } 
                { type:  'separator'}
                { label: 'Bezier',      accelerator: 'command+b',           click: -> action 'click', 'bezier_smooth'}
                { label: 'Line',        accelerator: 'command+l',           click: -> action 'click', 'line'}
                { label: 'Polygon',     accelerator: 'command+p',           click: -> action 'click', 'polygon'}
                { label: 'Width',       accelerator: 'command+\\',          click: -> action 'click', 'width'}
                { type:  'separator'}
                { label: 'Grid',        accelerator: 'command+9',           click: -> action 'click', 'grid'}
                { label: 'Zoom',        accelerator: 'command+0',           click: -> action 'click', 'zoom'}
                { label: 'Center',      accelerator: 'command+e',           click: -> action 'center'}
            ]
        ,
            # 000   000  000  000   000  0000000     0000000   000   000
            # 000 0 000  000  0000  000  000   000  000   000  000 0 000
            # 000000000  000  000 0 000  000   000  000   000  000000000
            # 000   000  000  000  0000  000   000  000   000  000   000
            # 00     00  000  000   000  0000000     0000000   00     00
            
            label: 'Window', submenu: [
                { label: 'Minimize',           accelerator: 'Alt+Cmd+M',        click: (i,win) -> win?.minimize()}
                { label: 'Maximize',           accelerator: 'Cmd+Shift+m',      click: (i)     -> app.toggleMaximize()}
                { type:  'separator'}
                { label: 'Bring All to Front', accelerator: 'Alt+Cmd+`',        role: 'front'}
                { type:  'separator'}
                { label: 'Reload Window',      accelerator: 'Ctrl+Alt+Cmd+L',   click: (i,win) -> app.reloadWin win}
                { label: 'Toggle DevTools',    accelerator: 'Cmd+Alt+I',        click: (i,win) -> win?.webContents.toggleDevTools()}
            ]
        ,        
            # 000   000  00000000  000      00000000 
            # 000   000  000       000      000   000
            # 000000000  0000000   000      00000000 
            # 000   000  000       000      000      
            # 000   000  00000000  0000000  000      
            
            label: 'Help', role: 'help', submenu: []            
        ]

module.exports = Menu

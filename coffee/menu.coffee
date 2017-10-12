# 00     00  00000000  000   000  000   000
# 000   000  000       0000  000  000   000
# 000000000  0000000   000 0 000  000   000
# 000 0 000  000       000  0000  000   000
# 000   000  00000000  000   000   0000000 

{ post, log }  = require 'kxk'

pkg      = require '../package.json'
electron = require 'electron'

action = (action, arg)  -> post.toWins 'tool', action, arg
button = (tool, button) -> post.toWins 'tool', 'button', tool, button

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
                { label: 'New',             accelerator: 'command+n',       click: -> action 'new'}
                { label: 'Clear',           accelerator: 'command+k',       click: -> action 'clear'}
                { label: 'Reload',          accelerator: 'command+r',       click: -> action 'load'}
                { type:  'separator'}
                { label: 'Open Recent...',  accelerator: 'command+.',       click: -> action 'browse'}
                { label: 'Open...',         accelerator: 'command+o',       click: -> action 'open'}
                { type:  'separator'}
                { label: 'Save',            accelerator: 'command+s',       click: -> action 'save'}
                { label: 'Save As...',      accelerator: 'command+shift+s', click: -> action 'saveAs'}
                { type:  'separator'}
                { label: 'Import...',       accelerator: 'o',               click: -> action 'import'}
                { label: 'Export...',       accelerator: 'command+alt+s',   click: -> action 'export'}
                { type:  'separator'}    
            ]
        ,
            # 00000000  0000000    000  000000000  
            # 000       000   000  000     000     
            # 0000000   000   000  000     000     
            # 000       000   000  000     000     
            # 00000000  0000000    000     000     
            
            label: 'Edit', submenu: [
                { label: 'Align', submenu: [
                    { label: 'Left',    accelerator: '1',           click: -> button 'align', 'left'}
                    { label: 'Right',   accelerator: 'command+1',   click: -> button 'align', 'right'}
                    { type:  'separator'}                                             
                    { label: 'Center',  accelerator: '2',           click: -> button 'align', 'center'}
                    { label: 'Middle',  accelerator: '3',           click: -> button 'align', 'mid'}
                    { type:  'separator'}                                             
                    { label: 'Top',     accelerator: '4',           click: -> button 'align', 'top'}
                    { label: 'Bottom',  accelerator: 'command+4',   click: -> button 'align', 'bot'}
                    { type:  'separator'}
                    { label: 'Space Horizontal', accelerator: '5',         click: -> button 'space', 'horizontal'}
                    { label: 'Space Vertical',   accelerator: 'command+5', click: -> button 'space', 'vertical'}
                ]}
                { label: 'Convert',     submenu: [
                    { label: 'Quad',    accelerator: 'ctrl+q',              click: -> post.toWins 'convert', 'Q'}
                    { label: 'Cubic',   accelerator: 'ctrl+c',              click: -> post.toWins 'convert', 'C'}
                    { label: 'Smooth',  accelerator: 'ctrl+s',              click: -> post.toWins 'convert', 'S'}
                    { label: 'Polygon', accelerator: 'ctrl+m',              click: -> post.toWins 'convert', 'P'}
                    { label: 'Divide',  accelerator: 'ctrl+d',              click: -> post.toWins 'convert', 'D'}
                ]}
                { label: 'Order', submenu: [
                    { label: 'Front',       accelerator: 'command+alt+up',  click: -> button 'send',  'front'}
                    { label: 'Raise',       accelerator: 'command+up',      click: -> button 'order', 'forward'}
                    { label: 'Lower',       accelerator: 'command+down',    click: -> button 'order', 'backward'}
                    { label: 'Back',        accelerator: 'command+alt+down',click: -> button 'send',  'back' }
                ]}
                { label: 'Select', submenu: [
                    { label: 'All',         accelerator: 'command+a',       click: -> action 'selectAll'}
                    { label: 'None',        accelerator: 'command+d',       click: -> action 'deselect'}
                    { label: 'Invert',      accelerator: 'command+i',       click: -> action 'invert'}        
                ]}
                { label: 'Flip', submenu: [
                    { label: 'Horizontal',  accelerator: '6',               click: -> button 'flip', 'horizontal'}
                    { label: 'Vertical',    accelerator: 'command+6',       click: -> button 'flip', 'vertical'}
                ]}
                { type:  'separator'}
                { label: 'Group',       accelerator: 'command+g',           click: -> action 'group'}
                { label: 'Ungroup',     accelerator: 'command+u',           click: -> action 'ungroup'}
                { type:  'separator'}
                { label: 'Mask',        accelerator: 'm',                   click: -> button 'mask', 'mask'}
                { label: 'Unmask',      accelerator: 'command+m',           click: -> button 'mask', 'unmask'}
                { type:  'separator'}
                { label: 'Cut',         accelerator: 'command+x',           click: -> action 'cut'}
                { label: 'Copy',        accelerator: 'command+c',           click: -> action 'copy'}
                { label: 'Paste',       accelerator: 'command+v',           click: -> action 'paste'}
                { type:  'separator'}
                { label: 'Undo',        accelerator: 'command+z',           click: -> action 'undo'}
                { label: 'Redo',        accelerator: 'command+shift+z',     click: -> action 'redo'}
            ]
        ,
            # 000000000   0000000    0000000   000      
            #    000     000   000  000   000  000      
            #    000     000   000  000   000  000      
            #    000     000   000  000   000  000      
            #    000      0000000    0000000   0000000  
            
            label: 'Tool', submenu: [
                
                { type:  'separator'}
                { label: 'Zoom',        submenu: [
                    { label:'Reset',    accelerator: 'command+0',   click: -> button 'zoom', 'reset' }
                    { label:'Out',      accelerator: 'command+-',   click: -> button 'zoom', 'out'  }
                    { label:'In',       accelerator: 'command+=',   click: -> button 'zoom', 'in'  }
                ] }
                { label: 'Toggle',      submenu: [
                    { label: 'Padding',     accelerator: 'p',               click: -> button 'padding', 'show'}
                    { label: 'Fill/Stroke', accelerator: 'command+7',       click: -> action 'swapColor'}
                    { label: 'Properties',  accelerator: 'command+t',       click: -> action 'toggleProperties'}
                    { label: 'Tools',       accelerator: 'command+shift+t', click: -> action 'toggleTools'}
                    { label: 'Groups',      accelerator: 'command+shift+g', click: -> button 'show', 'groups'}
                    { label: 'IDs',         accelerator: 'command+shift+i', click: -> button 'show', 'ids'}
                    { label: 'Wire',        accelerator: 'w',               click: -> button 'wire', 'wire'}
                    { label: 'Unwire',      accelerator: 'command+w',       click: -> button 'wire', 'unwire'}
                ]
                }
                { type:  'separator'}
                { label: 'Bezier',      accelerator: 'command+b',   click: -> action 'click', 'bezier_smooth'}
                { label: 'Polygon',     accelerator: 'command+p',   click: -> action 'click', 'polygon'}
                { label: 'Line',        accelerator: 'l',           click: -> action 'click', 'line'}
                { label: 'Text',        accelerator: 't',           click: -> action 'click', 'text'}                
                { type:  'separator'}
                { label: 'Grid',        accelerator: 'command+9',   click: -> button 'grid', 'grid'}
                { label: 'Center',      accelerator: 'command+e',   click: -> action 'center'}
            ]
        ,
            # 000   000  000  00000000  000   000  
            # 000   000  000  000       000 0 000  
            #  000 000   000  0000000   000000000  
            #    000     000  000       000   000  
            #     0      000  00000000  00     00  
            
            label: 'View', submenu: [
                { label: 'Layers',      accelerator: 'command+l',   click: -> action 'layer'}
                { label: 'Fonts',       accelerator: 'command+f',   click: -> action 'font'}
                { label: 'Gradients',   accelerator: 'command+j',   click: -> action 'gradient'}
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

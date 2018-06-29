#!/usr/bin/env bash
cd `dirname $0`/..

if rm -rf kaligraf-win32-x64; then
    
    konrad
    
    node_modules/.bin/electron-rebuild
    
    IGNORE="(.*\.dmg$|Icon$|.*md$|/inno$|/svg$|/pug$|/styl$|.*\.lock$|bin$|kali.png|browser.png|shot.*\.png|.*\.bmp|.*\.icns)"
    node_modules/electron-packager/cli.js . --overwrite --icon=img/app.ico --ignore $IGNORE
    
    rm -rf kaligraf-win32-x64/resources/app/inno
fi

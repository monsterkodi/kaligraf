#!/usr/bin/env bash
cd `dirname $0`/..

konrad

node_modules/.bin/electron-rebuild

IGNORE="(.*\.dmg$|Icon$|coffee$|.*md$|/inno$|/svg$|/pug$|/styl$|.*\.noon$|.*\.lock$|bin$|kali.png|browser.png|shot.*\.png|.*\.bmp|.*\.icns)"
node_modules/electron-packager/cli.js . --overwrite --icon=img/kaligraf.ico --ignore $IGNORE

mkdir kaligraf-win32-x64/resources/app/coffee
cp -f ./coffee/menu.noon kaligraf-win32-x64/resources/app/coffee

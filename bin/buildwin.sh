#!/usr/bin/env bash
cd `dirname $0`/..

konrad

node_modules/.bin/electron-rebuild

IGNORE="/(.*\.dmg$|Icon$|coffee$|.*md$|pug$|styl$|.*\.noon$|.*\.lock$|bin/dmg.*)"
node_modules/electron-packager/cli.js . --overwrite --icon=bin/kaligraf.ico --ignore $IGNORE

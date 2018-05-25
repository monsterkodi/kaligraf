#!/usr/bin/env bash
cd `dirname $0`/..

NAME=kaligraf

2>/dev/null 1>/dev/null killall $NAME
2>/dev/null 1>/dev/null killall $NAME

konrad

IGNORE="/(.*\.dmg$|Icon$|coffee$|.*md$|pug$|styl$|.*\.noon$|.*\.lock$|bin/dmg.*)"
node_modules/electron-packager/cli.js . --overwrite --icon=bin/$NAME.icns --ignore $IGNORE --extend-info ./bin/info.plist --extra-resource ./bin/file.icns

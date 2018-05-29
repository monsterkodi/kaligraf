#!/usr/bin/env bash
cd `dirname $0`/..

NAME=kaligraf

2>/dev/null 1>/dev/null killall $NAME
2>/dev/null 1>/dev/null killall $NAME

konrad --run

IGNORE="/(.*\.dmg$|Icon$|coffee$|.*md$|pug$|styl$|.*\.noon$|.*\.lock$|bin/dmg.*)"
node_modules/electron-packager/cli.js . --overwrite --icon=img/$NAME.icns --ignore $IGNORE --extend-info ./bin/info.plist --extra-resource ./img/file.icns

rm $NAME-darwin-x64/LICENSE*
rm $NAME-darwin-x64/version

#cp ./coffee/menu.noon $NAME-darwin-x64/resources/app/coffee
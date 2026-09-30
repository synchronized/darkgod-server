#!/bin/sh
#
CURRDIR=$(cd "$(dirname "$0")";pwd)
PROJECTDIR=$(dirname "$(dirname "${CURRDIR}")")

$PROJECTDIR/3rd/skyuv/3rd/skynet/3rd/lua/lua $PROJECTDIR/client/simpleclient.lua $PROJECTDIR $1

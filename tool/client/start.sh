#!/bin/sh

set -eu

CURRDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECTDIR=$(dirname "$(dirname "$CURRDIR")")
LUA=${LUA:-${PROJECTDIR}/3rd/skyuv/3rd/skynet/3rd/lua/lua}
SKYUV_LUACLIB=${SKYUV_LUACLIB:-${PROJECTDIR}/3rd/skyuv/build/darkgod/3rd/portable/luaclib}

exec "${LUA}" "${PROJECTDIR}/client/simpleclient.lua" "${PROJECTDIR}" "${1:-}" "${2:-}" "${3:-}" "${SKYUV_LUACLIB}"

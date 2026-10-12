#!/bin/sh

set -eu

CURRDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECTDIR=$(dirname "$(dirname "$CURRDIR")")
PRESET=${DARKGOD_PRESET:-linux-gcc-debug}
LUA=${LUA:-${PROJECTDIR}/3rd/skyuv/build/darkgod/3rd/lua}
SKYUV_LUACLIB=${SKYUV_LUACLIB:-${PROJECTDIR}/3rd/skyuv/build/darkgod/3rd/portable/luaclib}
MODULE_ROOT=${DARKGOD_MODULE_ROOT:-${PROJECTDIR}/build/${PRESET}/project/modules}

if [ ! -x "$LUA" ]; then
    echo "Lua interpreter not found: $LUA" >&2
    exit 1
fi
if [ ! -d "$SKYUV_LUACLIB" ]; then
    echo "skyuv Lua module directory not found: $SKYUV_LUACLIB" >&2
    exit 1
fi
if [ ! -d "$MODULE_ROOT" ]; then
    echo "project Lua module directory not found: $MODULE_ROOT" >&2
    exit 1
fi

echo "Preset:         $PRESET"
echo "Lua:            $LUA"
echo "skyuv modules:  $SKYUV_LUACLIB"
echo "project modules: $MODULE_ROOT"

exec "${LUA}" "${PROJECTDIR}/client/simpleclient.lua" "${PROJECTDIR}" "${1:-}" "${2:-}" "${3:-}" "${SKYUV_LUACLIB}" "${MODULE_ROOT}"

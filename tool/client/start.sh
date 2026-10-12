#!/bin/sh

set -eu

CURRDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECTDIR=$(dirname "$(dirname "$CURRDIR")")
PRESET=${DARKGOD_PRESET:-linux-gcc-debug}
LUA=${LUA:-${PROJECTDIR}/3rd/skyuv/build/darkgod/3rd/lua}
SKYUV_LUACLIB=${SKYUV_LUACLIB:-${PROJECTDIR}/3rd/skyuv/build/darkgod/3rd/portable/luaclib}
MODULE_ROOT=${DARKGOD_MODULE_ROOT:-${PROJECTDIR}/build/${PRESET}/project/modules}

exec "${LUA}" "${PROJECTDIR}/client/simpleclient.lua" "${PROJECTDIR}" "${1:-}" "${2:-}" "${3:-}" "${SKYUV_LUACLIB}" "${MODULE_ROOT}"

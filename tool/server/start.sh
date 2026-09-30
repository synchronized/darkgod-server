#!/bin/sh

set -e
CURRDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECTDIR=$(dirname "$(dirname "$CURRDIR")")
PRESET=${DARKGOD_PRESET:-linux-gcc-debug}
RUNTIME="$PROJECTDIR/build/$PRESET/project/bin/skyuv"
CONFIG=${DARKGOD_CONFIG:-"build/$PRESET/project/config/config-skyuv-pb.lua"}

if [ ! -x "$RUNTIME" ]; then
    echo "skyuv runtime not found: $RUNTIME" >&2
    echo "Build with: cmake --preset $PRESET && cmake --build --preset $PRESET" >&2
    exit 1
fi

export SERVER_NAME=smmo
export OS=${OS:-$(uname -s)}
cd "$PROJECTDIR"

if [ -z "${DARKGOD_CONFIG:-}" ]; then
    mkdir -p "build/$PRESET/project/config"
    sed \
        -e "s#darkgod_build_root = .*#darkgod_build_root = \"build/$PRESET/project\"#" \
        -e "s#darkgod_build_configuration = .*#darkgod_build_configuration = \"${DARKGOD_CONFIGURATION:-Debug}\"#" \
        server/config-skyuv-pb.lua > "$CONFIG"
fi

exec "$RUNTIME" "$CONFIG"

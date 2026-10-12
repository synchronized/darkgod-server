#!/bin/sh

set -e
CURRDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECTDIR=$(dirname "$(dirname "$CURRDIR")")
PRESET=${DARKGOD_PRESET:-linux-gcc-debug}
RUNTIME="$PROJECTDIR/build/$PRESET/project/bin/skyuv"
CONFIG=${DARKGOD_CONFIG:-"build/$PRESET/project/config/config-skyuv-pb.lua"}
PID_DIR="$PROJECTDIR/var/server"
PID_FILE="$PID_DIR/server.pid"
LOG_FILE="$PID_DIR/server.log"

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

if [ "${DARKGOD_BACKGROUND:-0}" = "1" ]; then
	mkdir -p "$PID_DIR"
	if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null \
		&& [ "$(ps -p "$(cat "$PID_FILE")" -o comm= 2>/dev/null | tr -d ' ')" = "skyuv" ]; then
		echo "skyuv server already running (PID $(cat "$PID_FILE"))"
	exit 0
	fi
	"$RUNTIME" "$CONFIG" >"$LOG_FILE" 2>&1 &
	echo $! >"$PID_FILE"
	echo "skyuv server started in background (PID $(cat "$PID_FILE"))"
	exit 0
fi

exec "$RUNTIME" "$CONFIG"

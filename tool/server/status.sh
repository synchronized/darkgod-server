#!/bin/sh

set -eu

CURRDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECTDIR=$(dirname "$(dirname "$CURRDIR")")
PID_FILE="${PROJECTDIR}/var/server/server.pid"

if [ ! -f "$PID_FILE" ]; then
	echo "skyuv server stopped"
	exit 0
fi

PID=$(cat "$PID_FILE")
if kill -0 "$PID" 2>/dev/null \
	&& [ "$(ps -p "$PID" -o comm= 2>/dev/null | tr -d ' ')" = "skyuv" ]; then
	echo "skyuv server running (PID $PID)"
else
	echo "skyuv server stale PID file: $PID_FILE"
exit 1
fi

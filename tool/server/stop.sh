#!/bin/sh

set -eu

CURRDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECTDIR=$(dirname "$(dirname "$CURRDIR")")
PID_FILE="${PROJECTDIR}/var/server/server.pid"

if [ ! -f "$PID_FILE" ]; then
	echo "skyuv server is not running (no PID file)"
	exit 0
fi

PID=$(cat "$PID_FILE")
case "$PID" in
	''|*[!0-9]*) echo "invalid server PID file: $PID_FILE" >&2; exit 1 ;;
esac

if ! kill -0 "$PID" 2>/dev/null \
	|| [ "$(ps -p "$PID" -o comm= 2>/dev/null | tr -d ' ')" != "skyuv" ]; then
	rm -f "$PID_FILE"
	echo "skyuv server is not running"
	exit 0
fi

kill "$PID"
attempt=0
while kill -0 "$PID" 2>/dev/null && [ "$attempt" -lt 20 ]; do
	sleep 0.25
	attempt=$((attempt + 1))
done

if kill -0 "$PID" 2>/dev/null; then
	echo "skyuv server did not stop cleanly (PID $PID)" >&2
	exit 1
fi

rm -f "$PID_FILE"
echo "skyuv server stopped"


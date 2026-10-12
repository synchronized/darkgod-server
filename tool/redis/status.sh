#!/bin/sh

set -eu

CURRDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECTDIR=$(dirname "$(dirname "$CURRDIR")")
INSTANCE_COUNT=${REDIS_INSTANCE_COUNT:-2}
BASEPORT=${REDIS_BASE_PORT:-6379}

index=0
while [ "$index" -lt "$INSTANCE_COUNT" ]; do
	PORT=$((index + BASEPORT))
	if redis-cli -h 127.0.0.1 -p "$PORT" ping >/dev/null 2>&1; then
		state=running
	else
		state=stopped
	fi
	echo "127.0.0.1:${PORT} ${state}"
	index=$((index + 1))
done

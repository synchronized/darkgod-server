#!/bin/sh

set -eu

CURRDIR=$(cd "$(dirname "$0")";pwd)
PROJECTDIR=$(dirname "$(dirname "${CURRDIR}")")
DATA_ROOT="${PROJECTDIR}/var/redis"
INSTANCE_COUNT=${REDIS_INSTANCE_COUNT:-2}
BASEPORT=${REDIS_BASE_PORT:-6379}

index=0
while [ "$index" -lt "$INSTANCE_COUNT" ]; do
	NAME="redis${index}"
	DIR="${DATA_ROOT}/${NAME}"
	PORT=$((index + BASEPORT))
	PIDFILE="${DIR}/.launcher.pid"
	if [ -f "${PIDFILE}" ] && kill -0 "$(cat "${PIDFILE}")" 2>/dev/null; then
		redis-cli -h 127.0.0.1 -p "${PORT}" shutdown >/dev/null 2>&1 || true
		echo "Redis stopped on 127.0.0.1:${PORT}"
	fi
	rm -f "${PIDFILE}"
	index=$((index + 1))
done

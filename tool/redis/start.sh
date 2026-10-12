#!/bin/sh

set -eu

CURRDIR=$(cd "$(dirname "$0")";pwd)
PROJECTDIR=$(dirname "$(dirname "${CURRDIR}")")
DATA_ROOT="${PROJECTDIR}/var/redis"
INSTANCE_COUNT=${REDIS_INSTANCE_COUNT:-2}
BASEPORT=${REDIS_BASE_PORT:-6379}

"${CURRDIR}/setup.sh" "${DATA_ROOT}" "${INSTANCE_COUNT}" "${BASEPORT}"

index=0
while [ "$index" -lt "$INSTANCE_COUNT" ]; do
	NAME="redis${index}"
	DIR="${DATA_ROOT}/${NAME}"
	PORT=$((index + BASEPORT))
	PIDFILE="${DIR}/.launcher.pid"
	if redis-cli -h 127.0.0.1 -p "${PORT}" ping >/dev/null 2>&1; then
		echo "Redis already running on 127.0.0.1:${PORT}"
		index=$((index + 1))
		continue
	fi
	(
		cd "${DIR}"
		exec redis-server "${NAME}.conf"
	) >"${DIR}/${NAME}.log" 2>&1 &
	echo $! >"${PIDFILE}"
	ready=0
	attempt=0
	while [ "$attempt" -lt 20 ]; do
		if redis-cli -h 127.0.0.1 -p "${PORT}" ping >/dev/null 2>&1; then
			ready=1
			break
		fi
		sleep 0.25
		attempt=$((attempt + 1))
	done
	if [ "$ready" -ne 1 ]; then
		echo "Redis failed to start on 127.0.0.1:${PORT}; see ${DIR}/${NAME}.log" >&2
		exit 1
	fi
	echo "Redis started on 127.0.0.1:${PORT}"
	index=$((index + 1))
done

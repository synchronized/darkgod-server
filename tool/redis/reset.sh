#!/bin/sh

set -eu

CURRDIR=$(cd "$(dirname "$0")";pwd)
PROJECTDIR=$(dirname "$(dirname "${CURRDIR}")")

"${CURRDIR}/stop.sh"

DATA_ROOT="${PROJECTDIR}/var/redis"
INSTANCE_COUNT=${REDIS_INSTANCE_COUNT:-2}

index=0
while [ "$index" -lt "$INSTANCE_COUNT" ]; do
	NAME="redis${index}"
	DIR="${DATA_ROOT}/${NAME}"
	if [ -d "${DIR}" ]; then
		rm -f "${DIR}/${NAME}.rdb" "${DIR}/${NAME}.aof"
	fi
	index=$((index + 1))
done

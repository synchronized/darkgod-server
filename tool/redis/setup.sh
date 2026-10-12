#!/bin/sh

set -eu

CURRDIR=$(cd "$(dirname "$0")";pwd)
TEMPLATE="${CURRDIR}/redis.conf"

PROJECTDIR=$(dirname "$(dirname "${CURRDIR}")")
TARGET=${1:-${PROJECTDIR}/var/redis}
INSTANCE_COUNT=${2:-2}
BASEPORT=${3:-${REDIS_BASE_PORT:-6379}}

case "$INSTANCE_COUNT" in
	''|*[!0-9]*) echo "instance count must be a non-negative integer" >&2; exit 2 ;;
esac

mkdir -p "${TARGET}"

index=0
while [ "$index" -lt "$INSTANCE_COUNT" ]; do
	NAME="redis${index}"
	DIR="${TARGET}/${NAME}"
	mkdir -p "${DIR}"

	PORT=$((index + BASEPORT))
	PIDFILE="${NAME}.pid"
	LOGFILE="${NAME}.log"
	DBFILE="${NAME}.rdb"

	sed \
		-e "s@^daemonize .*@daemonize no@" \
		-e "s@^logfile .*@logfile \"\"@" \
		-e "s@^port .*@port ${PORT}@" \
		-e "s@^pidfile .*@pidfile ${PIDFILE}@" \
		-e "s@^dbfilename .*@dbfilename ${DBFILE}@" \
		-e "s@^dir .*@dir .@" \
		"${TEMPLATE}" > "${DIR}/${NAME}.conf"

	index=$((index + 1))
done

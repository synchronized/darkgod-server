#!/bin/bash

CURRDIR=$(cd "$(dirname "$0")";pwd)
PROJECTDIR=$(dirname "$(dirname "${CURRDIR}")")
PATH="${PATH}:${PROJECTDIR}/bin"
DATA_ROOT="${PROJECTDIR}/var"

for i in `seq 0 32`
do
	NAME="redis${i}"
	DIR="${DATA_ROOT}/${NAME}"
	if [ -d ${DIR} ]; then
		PORT=$(($i + 6379))
		redis-cli -p ${PORT} shutdown
	fi
done

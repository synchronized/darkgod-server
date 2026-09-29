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
		cd ${DIR}
		redis-server ${NAME}.conf
	fi
done

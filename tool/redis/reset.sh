#!/bin/bash

CURRDIR=$(cd "$(dirname "$0")";pwd)
PROJECTDIR=$(dirname "$(dirname "${CURRDIR}")")

${CURRDIR}/stop.sh

for i in `seq 0 32`
do
	NAME="redis${i}"
	DIR="${PROJECTDIR}/var/${NAME}"
	if [ -d ${DIR} ]; then
		rm ${DIR}/${NAME}.rdb
	fi
done

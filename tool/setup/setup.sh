#!/bin/bash

CURRDIR=$(cd "$(dirname "$0")";pwd)
PROJECTDIR=$(dirname "$(dirname "${CURRDIR}")")
TARGET="${PROJECTDIR}/var"

if [[ $# -gt 0 ]]
then
	REDIS_NUM=${1}
else
	REDIS_NUM=8
fi

echo "running setup..."
echo "target folder    : ${TARGET}"
echo "redis server num : ${REDIS_NUM}"

if [ ! -d "${TARGET}" ]
then
	  mkdir $TARGET
fi

${PROJECTDIR}/tool/redis/setup.sh ${TARGET} ${REDIS_NUM}

echo "setup finished."

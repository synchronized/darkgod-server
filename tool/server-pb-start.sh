#!/bin/bash
exec "$(cd "$(dirname "$0")"; pwd)/server/start.sh" "$@"

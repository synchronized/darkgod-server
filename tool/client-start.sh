#!/bin/bash
exec "$(cd "$(dirname "$0")"; pwd)/client/start.sh" "$@"

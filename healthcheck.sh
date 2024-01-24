#!/usr/bin/env bash
PID=$(cat ./.pid)
if [[ -z $PID ]]; then
    exit 1;
fi

VSIZE=$(pgrep -P $PID | xargs ps -o vsize -p | awk '{memory+=$1} END {print memory}')
if [[ -z $MAX_VSIZE ]]; then
    MAX_VSIZE=8000000;
fi

if [[ $MAX_VSIZE -le $VSIZE ]]; then
    exit 1;
fi

exit 0;
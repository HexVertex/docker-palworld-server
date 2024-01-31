#!/usr/bin/env bash

INSTALLED_BUILD=$(cat /data/steamapps/appmanifest_${APP_ID}.acf | grep -Po "^\s*\"buildid\"\s*\K\"(.*?)\"" | tr -d '"')
LATEST_BUILD=$(curl -s -X GET "https://api.steamcmd.net/v1/info/${APP_ID:-2394010}" | grep -Po "^.*branches.*public\": {\"buildid\":\s\K\"[0-9]*\"" | tr -d '"')

echo "INSTALLED_BUILD=$INSTALLED_BUILD"
echo "LATEST_BUILD=$LATEST_BUILD"

if [ "${INSTALLED_BUILD:-0}" -eq "${LATEST_BUILD:-0}" ]; then
    echo "Latest version is installed!"
else
    echo updating;
    steamcmd +force_install_dir /data +login anonymous +app_update ${APP_ID} +quit;
fi

LAUNCH_ARGS="-useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS $@"

if [ "$IS_COMMUNITY" = true ]; then
    LAUNCH_ARGS="EpicApp=PalServer $LAUNCH_ARGS"
fi

echo "/data/PalServer.sh ${LAUNCH_ARGS}"
set -m
/data/PalServer.sh ${LAUNCH_ARGS} &
PID="$!"

echo -n "$PID" | tee .pid
fg %1
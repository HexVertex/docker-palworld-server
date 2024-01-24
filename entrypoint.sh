#!/usr/bin/env bash

chown -R $USER:$USER /data
exec runuser -u $USER "$@"
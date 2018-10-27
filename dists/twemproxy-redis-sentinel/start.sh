#!/bin/sh

op=$1

cwd=$(cd $(dirname $0); pwd)
cd $cwd

appname=redis-sentinel

pidfile=logs/${appname}.pid
pid=""
if [ -f "$pidfile" ]; then
    pid=$(cat $pidfile)
fi

if [ -n "$pid" ]; then
    if [ "$op" = "restart" ]; then
        ./shutdown.sh
    else
        echo "process $pid is running"
        exit 0
    fi
fi

source ./env.sh

$PYTHON redis-sentinel.py


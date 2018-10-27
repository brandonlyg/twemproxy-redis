#!/bin/sh

cwd=$(cd $(dirname $0); pwd)

appname=redis-sentinel

pidfile=./logs/${appname}.pid

if [ ! -f $pidfile ]; then
    echo "$appname process not exists"
    exit 0
fi

pid=$(cat $pidfile)
echo "try to killing process $pid"

count=0
while [ $count -lt 100 ]; do
    procinfo=$(ps -ef|grep -w $pid|grep -v grep)
    if [ -z "$procinfo" ]; then
        echo "kill $appname $pid successful"
        rm -rf $pidfile
        exit 0
    fi

    kill $pid
    sleep 0.1
done


echo "kill $appname $pid failed"

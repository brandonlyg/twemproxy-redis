#!/bin/sh

appname=$1

#appname=nutcracker
pidfile=var/${appname}.pid


if [ ! -f "$pidfile" ]; then
        echo "no $appname process"
        exit
fi

pid=`cat $pidfile`

procinfo=$pid
while [ -n "$procinfo" ]; do
        kill $pid
        sleep 0.1
        procinfo=`ps -ef|grep $pid|grep -v grep`
done

rm -rf $pidfile

echo "$appname process $pid shutdown"

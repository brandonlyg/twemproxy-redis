#!/bin/sh

appname=$1
statsPort=$2

logfile=logs/${appname}.log
pidfile=var/${appname}.pid
conf=conf/${appname}.yml

if [ -f "$pidfile" ]; then
	rm -rf $pidfile
fi

cmd="sbin/nutcracker --daemonize --verbose=5 --stats-port=$statsPort --conf-file=$conf --output=$logfile --pid-file=$pidfile"
echo $cmd
$cmd

if [ "$?" != "0" ]; then
	echo "appname start failed"
	exit 1
fi

trycount=0

while [ "$trycount" -lt 10 ]; do
	if [ -f "$pidfile" ]; then
		break
	fi
	sleep 0.1
done

pid=`cat $pidfile`

echo "$appname start pid:$pid"

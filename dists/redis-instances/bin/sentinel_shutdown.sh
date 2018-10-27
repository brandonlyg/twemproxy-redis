#!/bin/sh

cwd=`cd $(dirname $0)/..;pwd`
cd $cwd

function shutdown_instance(){
	insname=""
	for arg in $@; do
		key=`echo $arg|awk -F= '{ print $1 }'`
		val=`echo $arg|awk -F= '{ print $2 }'`
		if [ $key = "name" ]; then
			insname=$val
			break
		fi
	done
	if [ -z "$insname" ]; then
		return 0
	fi

	insws="$cwd/data/$insname"
	cd $insws
	
	pidfile="$insws/var/sentinel.pid"
	
	pid=`cat $pidfile`
	
	procinfo=`ps -ef|grep -w $pid|grep -v grep`
	while [ -n "$procinfo" ]; do
		kill $pid
		sleep 0.5
		procinfo=`ps -ef|grep -w $pid|grep -v grep`
	done
	
	echo "redis sentinel process $pid shutdown"
	
	cd $cwd
}


while read data; do
	shutdown_instance $data
done < config/sentinel.conf


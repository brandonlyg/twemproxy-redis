#!/bin/sh

cwd=`cd $(dirname $0)/..;pwd`
cd $cwd

source ./bin/env.sh

updateconfig=$1

CMDCP=/usr/bin/cp
if [ -f "/bin/cp" ]; then
	CMDCP=/bin/cp
fi

monitorconf="sentinel_monitor.conf"

function init_instance(){
	insinfo=$@
	insname=""
	for arg in $insinfo; do
		key=`echo $arg|awk -F= '{ print $1 }'`
		if [ $key = "name" ]; then
			insname=`echo $arg|awk -F= '{ print $2 }'`
			break
		fi	
	done
	#echo $insname	
	insws="data/$insname"
	mkdir -p "$insws/config"
	mkdir -p "$insws/var"
	
	missconfig="false"
	if [ ! -f "$insws/config/${monitorconf}" ]; then
		missconfig="true"
	fi

	if [ "$missconfig" = "true" -o "$updateconfig" = "updateconfig" ]; then
		echo "update config"
		$CMDCP ${cwd}/config/${monitorconf} ${insws}/config/${monitorconf}
	fi
}

function start_instance(){
	insinfo=$@
	args=""
	insname=""
	#echo "start instance $insinfo"
	for arg in $insinfo; do
		key=`echo $arg|awk -F= '{ print $1 }'`
		val=`echo $arg|awk -F= '{ print $2 }'`
		#echo "$key $val"
		if [ $key = "name" ]; then
			insname=$val
		else
			args="$args--$key $val "
		fi
	done
	
	curws="$cwd/data/$insname"
	cd $curws
	
	pidfile="$curws/var/sentinel.pid"
	logfile="$curws/var/sentinel.log"
	
	args="--sentinel $args --pidfile $pidfile"
	args="$args --logfile $logfile"

	cmd="${redishome}/bin/redis-server $curws/config/${monitorconf} $args"
	echo $cmd
	$cmd
	
	sleep 0.1
	pid=`cat $pidfile`
	echo "resdis sentinel start pid: $pid"	

	cd $cwd
}

while read data; do
	if [ -z "$data" ]; then
		continue
	fi
	#echo $data
	init_instance $data
	start_instance $data	
done < $cwd/config/sentinel.conf


#!/bin/sh

cwd=`cd $(dirname $0)/..;pwd`
cd $cwd

source ./bin/common.sh

gname=$1

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
	
	pidfile="$insws/var/redis.pid"
    if [ ! -f "$pidfile" ]; then
        echo "redis instance process not exist"
        continue
    fi
	
	pid=`cat $pidfile`
	
	procinfo=`ps -ef|grep -w $pid|grep -v grep`
	while [ -n "$procinfo" ]; do
		kill $pid
		sleep 0.1
		procinfo=`ps -ef|grep -w $pid|grep -v grep`
	done
	
	echo "redis process $pid shutdown"
	
	cd $cwd
}

insconfs=$(get_ins_confs $gname)
for fname in ${insconfs}; do
    while read data; do
        shutdown_instance $data
    done < ${cwd}/config/${fname}
done



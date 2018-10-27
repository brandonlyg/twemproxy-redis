#!/bin/sh

cwd=`cd $(dirname $0)/..;pwd`
cd $cwd

source ./bin/env.sh
source ./bin/common.sh

gname=$1
updateconfig=$2

CMDCP=/usr/bin/cp
if [ -f "/bin/cp" ]; then
    CMDCP=/bin/cp
fi

confname="redis.conf"

function init_instance(){
	local insinfo=$@
	local insname=""
	local insgname=""

	for arg in $insinfo; do
		key=`echo $arg|awk -F= '{ print $1 }'`
		val=`echo $arg|awk -F= '{ print $2 }'`
		if [ $key = "name" ]; then
			insname=$val
			insgname=$(echo $insname|sed -r 's/_\w+//g')
		fi	
	done
	#echo $insname	
	insws="data/$insname"
	mkdir -p "$insws/data"
	mkdir -p "$insws/var"
	mkdir -p "$insws/config"
	
	missconfig="false"
	if [ ! -f "$insws/config/$confname" ]; then
		missconfig="true"
	fi
		
	if [ "$missconfig" = "true" -o "$updateconfig" = "updateconfig" ]; then
		echo "update config $confname"
		$CMDCP "${cwd}/config/redis_parameters.conf" "$insws/config/$confname"
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
		elif [ $key = "slaveof" ]; then
			val=`echo $val|sed 's/:/ /g'`
			args="$args --$key $val"
		else
			args="$args --$key $val "
		fi
	done
	
	curws="$cwd/data/$insname"
	cd $curws
	
	pidfile="$curws/var/redis.pid"
	args="$args --pidfile $pidfile"
        logfile="$curws/var/redis.log"
        args="$args --logfile $logfile"
        	
	cmd="${redishome}/bin/redis-server $curws/config/$confname $args"
	echo $cmd
	$cmd
	
	sleep 0.1
	pid=`cat $pidfile`
	echo "resdis start pid: $pid"	

	cd $cwd
}

function start_group(){
    local conf=$1

    while read data; do
        if [ -z "$data" ]; then
            continue
        fi
        #echo $data
        init_instance $data
        start_instance $data
    done < ${cwd}/config/${conf}
}

insconfs=$(get_ins_confs $gname)
for fname in ${insconfs}; do
    start_group ${fname}
done




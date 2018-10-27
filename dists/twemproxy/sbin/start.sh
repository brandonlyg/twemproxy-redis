#!/bin/sh
#启动所有实例, 或指定实例

cwd=`cd $(dirname $0)/..;pwd`

cd $cwd

destname=$1

confs=$(ls conf/*.yml)
for conf in $confs; do
    confname=$(echo $conf|sed 's/conf\///g')
	appname=$(echo $confname|sed 's/\.yml//g')
	sname=$(echo $appname|sed -r 's/\-\w+//g')
	
    if [ -n "$destname" ]; then
        if [ "$destname" != "$sname" ]; then
            continue
        fi
    fi

    port=$(cat $conf|grep "listen:")
    port=$(echo $port|awk '{ print $2 }')
    port=$(echo $port|awk -F: '{ print $2 }')
    statsPort=$(expr $port + 1)

    sbin/dostart.sh $appname $statsPort

done


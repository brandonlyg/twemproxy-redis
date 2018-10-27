#!/bin/sh
#关闭所有实例

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

   sbin/doshutdown.sh $appname

done


#!/bin/sh

cwd=`cd $(dirname $0)/..;pwd`

cd $cwd

destname=$1

sbin/shutdown.sh $destname
sbin/start.sh $destname

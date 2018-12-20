#!/bin/sh
#生成redis sentinel配置

source ./common.sh

snl_conf="$gendir/sentinel.conf"
snlm_conf="$gendir/sentinel_monitor.conf"

procount=$(loadconf redis.sentinel.processes)
port=$(loadconf redis.sentinel.port)

#生成sentinel实例配置
if [ -f $snl_conf ]; then
	rm $snl_conf
fi

if [ "$procount" -eq "1" ]; then
	confstr="name=sentinel port=$port"
	echo $confstr |tee -a $snl_conf
elif [ "$procount" -gt "1" ]; then
	pronum=0
	while [ "$pronum" -lt "$procount" ]; do
		confstr="name=sentinel_${pronum} port=$port"
		echo $confstr |tee -a $snl_conf
		pronum=$(expr $pronum + 1)
		port=$(expr $port + 1)
	done
fi

#生成sentinel monitor配置
if [ -f $snlm_conf ]; then
	rm $snlm_conf
fi

echo "bind 0.0.0.0" |tee -a $snlm_conf
echo "daemonize yes" | tee -a $snlm_conf
echo " " |tee -a $snlm_conf




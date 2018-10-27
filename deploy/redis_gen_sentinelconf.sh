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

redisnum=0
for gname in $groups; do
    port=$(loadconf ${gname}.redis.port)

    redisauth=$(loadconf ${gname}.redis.option.requirepass)

    master_servers=$(get_redis_servers ${gname} master)

	for sname in $master_servers; do
	    ip=$(gethost_ip $sname)
	    procount=$(get_redis_processes $gname $sname)
        gport=$port

		pn=0
		while [ "$pn" -lt "$procount" ]; do
			redisname="redis_${redisnum}"	
			echo "sentinel monitor $redisname $ip $gport 2" |tee -a $snlm_conf
			echo "sentinel down-after-milliseconds $redisname 30000" |tee -a $snlm_conf
			echo "sentinel failover-timeout $redisname 30000" |tee -a $snlm_conf
			echo "sentinel parallel-syncs $redisname 1" |tee -a $snlm_conf
			if [ -n "$redisauth" ]; then
			    echo "sentinel auth-pass $redisname $redisauth" |tee -a $snlm_conf
			fi
			echo " " |tee -a $snlm_conf
			
			redisnum=$(expr $redisnum + 1)
			gport=$(expr $gport + 1)
			pn=$(expr $pn + 1)
		done
	done

done



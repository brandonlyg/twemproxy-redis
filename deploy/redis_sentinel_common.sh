#!/bin/sh
#生成redis sentinel配置

source ./common.sh

function gen_sentinel_commands(){
    local gname=$1
    local port=$(loadconf ${gname}.redis.port)
    local redisauth=$(loadconf ${gname}.redis.option.requirepass)
    local master_servers=$(get_redis_servers ${gname} master)

    if [ -z "$port" -o -z "${master_servers}" ]; then
        echo ""
        return 1
    fi

    local total=0
    local sname=""
    for sname in ${master_servers}; do
	    local ip=$(gethost_ip $sname)
	    local procount=$(get_redis_processes $gname $sname)
        local gport=$port

		local pn=0
		while [ "$pn" -lt "$procount" ]; do
			redisname="redis_${gname}_${total}"
			echo "sentinel monitor $redisname $ip $gport 2"
			echo "sentinel set $redisname down-after-milliseconds 30000"
			echo "sentinel set $redisname failover-timeout 30000"
			echo "sentinel set $redisname parallel-syncs 1"
			if [ -n "$redisauth" ]; then
			    echo "sentinel set $redisname auth-pass $redisauth"
			fi
			echo ""

			gport=$(expr ${gport} + 1)
			pn=$(expr ${pn} + 1)
			total=$(expr ${total} + 1)
		done
	done
}

#rm tmp/tmp.txt
#gen_sentinel_commands test | tee -a tmp/tmp.txt
#echo $?

function get_sentinal_address(){
    local addr_list=""
    local sname=""

    local procount=$(loadconf redis.sentinel.processes)
    local port=$(loadconf redis.sentinel.port)

    for sname in ${sentinel_servers}; do
        local ip=$(gethost_ip ${sname})
        local idx=0
        while [ "${idx}" -lt "${procount}" ]; do
            local cur_port=$(expr ${port} + ${idx})
            local addr="${ip}:${cur_port}"
            if [ -n "${addr_list}" ]; then
                addr_list="${addr_list} "
            fi
            addr_list="${addr_list}${addr}"

            idx=$(expr ${idx} + 1)
        done

    done
    echo ${addr_list}
}

#get_sentinal_address


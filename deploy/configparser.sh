#!/bin/sh

#配置文件解析器

source ./common.sh

#得到twemproxy节点列表
function get_twemproxy_nodes(){
    group=$1
    redisauth=$(loadconf ${group}.redis.option.requirepass)
	twemport=$(loadconf ${group}.twemproxy.port)
	procnum=$(loadconf ${group}.twemproxy.processes)
	#echo "procnum $procnum"

    local servers=$(get_twemproxy_servers $group)

	res=""
	for sname in $servers; do
	    #echo "sname $sname"
	    ip=$(gethost_ip $sname)

	    port=$twemport
	    procidx=0
        while [ $procidx -lt $procnum ]; do
            if [ -n "$res" ]; then
                res="$res "
            fi
	        res="${res}${ip}:${port}:${redisauth}"
	        procidx=$(expr $procidx + 1)
	        port=$(expr $port + 2)
	    done
	done

	echo -n $res
}

#得到redis节点列表
function get_redis_nodes(){
    group=$1
    servers=$(loadconf ${group}.redis.nodes)
    port=$(loadconf ${group}.redis.port)
    password=$(loadconf ${group}.redis.option.requirepass)

    if [ -z "$servers" ]; then
        servers=${redis_servers}
    else
        servers=$(echo $servers|sed 's/,/ /g')
    fi

    res=""
    for spair in $servers; do
        sm=$(echo $spair|awk -F\- '{ print $1 }')
        ss=$(echo $spair|awk -F\- '{ print $2 }')

        m_ip=$(gethost_ip $sm)
        s_ip=$(gethost_ip $ss)

        local pcount=$(get_redis_processes $group $sm)

        pronum=0
        sport=$port
		while [ "$pronum" -lt "$pcount" ]; do
		    if [ -n "$res" ]; then
		        res="$res "
		    fi
		    res="${res}${m_ip}:${sport}:${password}-${s_ip}:${sport}:${password}"

			pronum=$(expr $pronum + 1)
			sport=$(expr $sport + 1)
		done

    done

    echo -n $res
}

#得到sentinel节点列表
function get_sentinel_nodes(){
    res=""
    for sname in ${sentinel_servers}; do
        ip=$(gethost_ip $sname)

        if [ -n "$res" ]; then
            res="$res "
        fi

        res="${res}${ip}:${sentinel_port}"
    done
    echo -n $res
}

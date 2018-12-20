#!/bin/sh
#公用代码

. ./getproperty.sh

configdir=../config
deployconf=$configdir/deploy.conf
hostsconf=$configdir/hosts.conf

function loadconf(){
    key=$1
    val=$(get_property $deployconf $key)
        
    echo $val
}

function getconf_by_prefix(){
	prek=$1
	#echo $prek
	val=$(get_multi_property_pair $deployconf $prek)
	
	echo $val
}

function get_redis_options(){
	gname=$1
	#echo "$gname"
	pairs=$(getconf_by_prefix ${gname}.redis.option)
	echo $pairs
}

function gethostconf(){
	hname=$1
	res=""
	while read data; do
		if [ -z "$data" ]; then
			continue
		fi
		comment=$(echo "$data"|grep -e "^#.*")
		if [ -n "$comment" ]; then
			continue
		fi	
	
		tmphname=$(echo $data|awk '{ print $1 }')
		if [ "$hname" = "$tmphname" ]; then
			res=$data
			break
		fi	
	done < $hostsconf
	echo $res
}

#gethostconf s01

function gethost_ip(){
	hname=$1
	info=$(gethostconf $hname)
	res=$(echo $info|awk '{ print $2 }')
	echo $res
}
#gethost_ip s01

function gethost_sshport(){
	hname=$1
        info=$(gethostconf $hname)
        res=$(echo $info|awk '{ print $3 }')
        echo $res
}

function gethost_user(){
        hname=$1
        info=$(gethostconf $hname)
        res=$(echo $info|awk '{ print $4 }')
        echo $res
}

function gethost_password(){
	hname=$1
        info=$(gethostconf $hname)
        res=$(echo $info|awk '{ print $5 }')
        echo $res
}

distsdir=../dists

tmpdir=./tmp
if [ ! -d "$tmpdir" ]; then
    mkdir $tmpdir
fi

gendir=${tmpdir}/genfiles
if [ ! -d "$gendir" ]; then
   mkdir $gendir
fi

redis_master_conf=${gendir}/redis_master_instance.conf

remote_tmpdir=$(loadconf remotetmpdir)

redis_servers=$(loadconf redis.server.nodes)
redis_servers=$(echo $redis_servers|sed 's/,/ /g')
redis_home=$(loadconf redis.home)
redis_inshome=$(loadconf redis.inshome)

twemproxy_servers=$(loadconf twemproxy.server.nodes)
twemproxy_servers=$(echo $twemproxy_servers|sed 's/,/ /g')
twemproxy_home=$(loadconf twemproxy.home)

python_home=$(loadconf python.home)

sentinel_servers=$(loadconf redis.sentinel.server.nodes)
sentinel_servers=$(echo $sentinel_servers|sed 's/,/ /g')
sentinel_inshome=$(loadconf redis.sentinel.inshome)
sentinel_port=$(loadconf redis.sentinel.port)
sentinel_processes=$(loadconf redis.sentinel.processes)

groups=$(loadconf groups)
groups=$(echo $groups|sed 's/,/ /g')


#得到redis host列表
function get_redis_servers(){
    #redistype: master, slave
    local gname=$1
    local redistype=""
    local servers=""

    if [ -z "$gname" ]; then
        echo ""
        exit
    fi

    if [ $# -gt 1 ]; then
        redistype=$2
    fi

    servers=$redis_servers

    tmps=$(loadconf ${gname}.redis.nodes)
    if [ -n "$tmps" ]; then
        servers=$(echo $tmps|sed 's/,/ /g')
    fi

    if [ "$redistype" != "master" -a "$redistype" != "slave" ]; then
        echo $servers
        exit
    fi

    nodes=""
    for spair in ${servers}; do
        sname=""
        if [ "${redistype}" = "master" ]; then
            sname=$(echo $spair|awk -F\- '{ print $1 }')
        elif [ "${redistype}" = "slave" ]; then
            sname=$(echo $spair|awk -F\- '{ print $2 }')
        fi
        if [ -n "$servers" ]; then
            nodes="$nodes "
        fi
        nodes="${nodes}${sname}"
    done

    echo "$nodes"
}

# 得到twemproxy host列表
function get_twemproxy_servers(){
    local gname=$1
    local servers=$(loadconf ${gname}.twemproxy.nodes)
    if [ -z "$servers" ]; then
	    servers=$twemproxy_servers
	else
	    servers=$(echo $servers|sed 's/,/ /g')
	fi

	echo "$servers"
}

# 得到redis在某个节点的进程数
function get_redis_processes(){
    local gname=$1
    local sname=$2
    local procount=$(loadconf ${gname}.redis.processes)

    local ndpc=$(loadconf ${gname}.redis.ndprocesses)
    if [ -n "$ndpc" ]; then
        ndpc=$(echo "$ndpc"|sed 's/,/ /g')
        local tmp=""
        for tmp in $ndpc; do
            local sn=$(echo $tmp|awk -F\: '{ print $1 }')
            local pn=$(echo $tmp|awk -F\: '{ print $2 }')
            if [ "$sn" = "$sname" ]; then
                procount=$pn;
                break
            fi
        done
    fi

    echo "$procount"
}

# 检查是某个目录是否部署在指定host上
function check_deployed(){
    local ip=$1
    local sshport=$2
    local user=$3
    local homedir=$4

    local exp="\[\$#\]"

    local res=$(expect << EOF
spawn ssh -p ${sshport} ${user}@${ip}
expect ${exp}
send "\[ \-d ${homedir} \]; echo \"exist=\$?\"\n"
expect ${exp}
send "logout\n"
expect eof
EOF
)

    res=$(echo "$res"|grep -e "^exist=[01]"|awk -F= '{ print $2 }')
    res=${res:0:1}
    if [ "0" = "$res" ]; then
        echo "true"
        return 0
    fi
    echo "false"
}
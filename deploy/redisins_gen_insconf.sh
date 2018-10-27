#!/bin/sh

source ./common.sh

confsdir=${gendir}/redis_ins_confs

# 删除旧的生成文件
rm -rf $confsdir

#生成master配置
function gen_master_conf(){
    local gname=$1
    local sname=$2
    local tmpmasterconf=$3

	local port=$(loadconf ${gname}.redis.port)
	local maxmemory=$(loadconf ${gname}.redis.maxmemory)
	local procount=$(get_redis_processes $gname $sname)

	#echo "procount $procount"

	mip=$(gethost_ip $sname)
    dir=$confsdir/${mip}
    if [ ! -d ${dir} ]; then
        mkdir -pv ${dir}
    fi

    local conf=${dir}/redis_${gname}-ins.conf

    local pronum=0
    while [ "$pronum" -lt "$procount" ]; do
        local tmp=$(get_redis_options $gname)
        local tmpconfstr="name=${gname}_$pronum port=$port $tmp"

        echo ">> $conf"
        echo "$tmpconfstr" | tee -a $conf

        echo "$tmpconfstr" >> $tmpmasterconf

        pronum=$(expr $pronum + 1)
        port=$(expr $port + 1)
    done

    echo "" >> $conf
}

#gen_master_conf test

#生成slave配置
function gen_slave_conf(){
    local ms=$1
    local ss=$2
    local masterconf=$3

    local mip=$(gethost_ip $ms)
    local sip=$(gethost_ip $ss)

    local dir=$confsdir/${sip}
    if [ ! -d ${dir} ]; then
        mkdir -pv ${dir}
    fi
    local conf=${dir}/redis_${gname}-ins.conf

    echo ">> $conf"
    local confstr
    while read confstr; do
        if [ -z "$confstr" ]; then
            continue
        fi
        port=$(echo $confstr|awk '{ print $2 }')
        port=$(echo $port|awk -F= '{ print $2 }')
        confstr="${confstr} slaveof=${mip}:${port}"
        echo $confstr |tee -a $conf
    done < $masterconf

    echo "" >> $conf
    echo ""
}

for gname in $groups; do
    echo "start gen group $gname"

    nodes=$(get_redis_servers $gname)
    for mss in $nodes; do
        ms=$(echo $mss|awk -F\- '{ print $1 }')
        ss=$(echo $mss|awk -F\- '{ print $2 }')

        tmpconf=${gendir}/tmpconf.conf
        if [ -f $tmpconf ]; then
            rm $tmpconf
        fi

        gen_master_conf $gname $ms $tmpconf

        gen_slave_conf $ms $ss $tmpconf

    done

done



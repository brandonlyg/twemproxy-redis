#!/bin/sh
#部署redis

#指定部署的group name(gname)
deploy_gname=$1

if [ -z "$deploy_gname" ]; then
    echo "miss param deploy gname"
    exit 1
fi

pkgname=redisins_install

#生成配置
./redisins_gen_insconf.sh $deploy_gname

#打包
./redisins_pack.sh $deploy_gname $pkgname
if [ "$?" != 0 ]; then
    echo "redis pack error"
    exit 1
fi

source ./common.sh

function get_all_servers(){
    local gname=""
    declare -A local mapsvrs=()
    for gname in $groups; do
        if [ "$gname" != "${deploy_gname}" ]; then
            continue
        fi

        local nodes=$(get_redis_servers $gname)
        for mss in $nodes; do
            ms=$(echo $mss|awk -F\- '{ print $1 }')
            ss=$(echo $mss|awk -F\- '{ print $2 }')

            mapsvrs["$ms"]=""
            mapsvrs["$ss"]=""
        done
    done

    local servers=""
    local snode=""
    for snode in ${!mapsvrs[@]}; do
        servers="${servers}${snode} "
    done

    echo "$servers"
}

servers=$(get_all_servers)
#部署到redis_servers的每一个host上
for sname in ${servers}; do
    echo "deploy redis $sname"

    ip=$(gethost_ip $sname)
	sshport=$(gethost_sshport $sname)
	user=$(gethost_user $sname)

	#初始化redis主机环境
	./init_host.sh $ip $sshport $user ${remote_tmpdir}

	#部署redis
	./redis_deploy.sh $sname

	#copy文件
	echo "copy install package to $sname $ip"
	scp -P $sshport tmp/${pkgname}.zip $user@$ip:${remote_tmpdir}

    #部署redis instance
	echo ""
	./deployhost.sh $ip $sshport $user $pkgname $remote_tmpdir
done


source ./redis_sentinel_common.sh

sentinel_addr=$(get_sentinal_address)
cmdfile=tmp/sentinel_cmds.txt
if [ -f "$cmdfile" ]; then
    rm $cmdfile
fi

gen_sentinel_commands ${deploy_gname} | tee -a ${cmdfile}

for addr in ${sentinel_addr}; do
    ../dists/python/bin/python redis_sentinel_setter.py ${addr} ${cmdfile}
done






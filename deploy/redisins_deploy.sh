#!/bin/sh
#部署redis

pkgname=redisins_install

#生成配置
./redisins_gen_insconf.sh

#打包
./redisins_pack.sh $pkgname
if [ "$?" != 0 ]; then
    echo "redis pack error"
    exit 1
fi

source ./common.sh

function get_all_servers(){
    local gname=""
    declare -A local mapsvrs=()
    for gname in $groups; do
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



#!/bin/sh
#部署redis sentinel

source ./common.sh

pkgname=redis_sentinel_install

#生成配置
./redis_sentinel_gen_insconfig.sh

#打包
./redis_sentinel_pack.sh $pkgname

#部署到sentinel_servers的每一个host上
for sname in ${sentinel_servers}; do
    ip=$(gethost_ip $sname)
	sshport=$(gethost_sshport $sname)
	user=$(gethost_user $sname)

	echo "deploy redis sentinel on ${sname}-${ip}"

	if [ "$(check_deployed ${ip} ${sshport} ${user} ${sentinel_inshome})" = "true" ]; then
	    echo "sentinel was deployed on ${ip}"
	    continue
	fi

	#初始化主机环境
	./init_host.sh $ip $sshport $user ${remote_tmpdir}

	#部署redis
	./redis_deploy.sh $sname

	#copy文件
	echo "copy install package to $sname $ip"
	scp -P $sshport tmp/${pkgname}.zip $user@$ip:${remote_tmpdir}

    #部署一台sentinel
	echo ""
	./deployhost.sh $ip $sshport $user $pkgname $remote_tmpdir
done



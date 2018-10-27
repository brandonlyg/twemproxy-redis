#!/bin/sh
#部署redis sentinel

pkgname=redis_sentinel_install

#生成配置
./redis_gen_sentinelconf.sh

#打包
./redis_sentinel_pack.sh $pkgname

source ./common.sh

#部署到sentinel_servers的每一个host上
for sname in ${sentinel_servers}; do
    echo "deploy redis sentinel on $sname"

    ip=$(gethost_ip $sname)
	sshport=$(gethost_sshport $sname)
	user=$(gethost_user $sname)

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



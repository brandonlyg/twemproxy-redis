#!/bin/sh
#部署twemproxy

pkgname=twpins_install

#生成配置
./twpins_gen_conf.sh

#打包
./twpins_pack.sh $pkgname

source ./common.sh
source ./twp_common.sh

servers=$(get_all_servers)
for sname in ${servers}; do
    ip=$(gethost_ip $sname)
    sshport=$(gethost_sshport $sname)
	user=$(gethost_user $sname)

	#初始化host
	./init_host.sh $ip $sshport $user ${remote_tmpdir}

    #部署twemproxy
    ./twp_deploy.sh $sname

	#部署python
	./python_deploy.sh $sname

    #copy文件
    echo "copy install package to $ip"
	scp -P $sshport tmp/${pkgname}.zip $user@$ip:${remote_tmpdir}

	#部署一个host
	echo ""
	./deployhost.sh $ip $sshport $user $pkgname $remote_tmpdir

done




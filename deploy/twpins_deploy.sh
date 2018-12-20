#!/bin/sh
#部署twemproxy

deploy_gname=$1

if [ -z "$deploy_gname" ]; then
    echo "miss param deploy gname"
    exit 1
fi

pkgname=twpins_install

#生成配置
./twpins_gen_conf.sh ${deploy_gname}

#打包
./twpins_pack.sh $pkgname ${deploy_gname}

source ./common.sh

servers=$(get_twemproxy_servers ${deploy_gname})
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




#!/bin/sh
#在目标主机上部署redis

cwd=$(cd $(dirname $0); pwd)

source ./common.sh

sname=$1
ip=$(gethost_ip $sname)
sshport=$(gethost_sshport $sname)
user=$(gethost_user $sname)

pkgname="redis_install"

exp="\[\$#\]"

#检查主机上是否已经部署了
echo "check redis on $ip"
res=$(expect << EOF
spawn ssh -p $sshport $user@$ip
expect $exp
send "\[ \-d ${redis_home} \]; echo \"redis-exist=\$?\"\n"
expect $exp
send "logout\n"
expect eof
EOF
)

res=$(echo "$res"|grep -e "^redis-exist=[01]"|awk -F= '{ print $2 }')
res=${res:0:1}
if [ "0" = "$res" ]; then
    echo "redis was deployed"
    exit 0
fi

# 打包
./redis_pack.sh $pkgname
if [ "$?" != 0 ]; then
    echo "redis pack error"
    exit 1
fi

#copy安装包
scp -P $sshport tmp/${pkgname}.zip $user@$ip:${remote_tmpdir}

#部署一台redis
echo ""
./deployhost.sh $ip $sshport $user $pkgname $remote_tmpdir





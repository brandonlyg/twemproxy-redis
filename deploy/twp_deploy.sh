#!/bin/sh
#在目标主机上部署twemproxy

cwd=$(cd $(dirname $0); pwd)

source ./common.sh

sname=$1
ip=$(gethost_ip $sname)
sshport=$(gethost_sshport $sname)
user=$(gethost_user $sname)

pkgname=twp_install

exp="\[\$#\]"

#检查主机上是否已经部署了
echo "check twemproxy on $ip"
res=$(expect << EOF
spawn ssh -p $sshport $user@$ip
expect $exp
send "\[ \-d ${twemproxy_home} \]; echo \"twp-exist=\$?\"\n"
expect $exp
send "logout\n"
expect eof
EOF
)

res=$(echo "$res"|grep -e "^twp-exist=[01]"|awk -F= '{ print $2 }')
res=${res:0:1}
if [ "0" = "$res" ]; then
    echo "twemproxy was deployed"
    exit 0
fi

# 打包
./twp_pack.sh $pkgname
if [ "$?" != 0 ]; then
    echo "twemproxy pack error"
    exit 1
fi

#copy安装包
scp -P $sshport tmp/${pkgname}.zip $user@$ip:${remote_tmpdir}

#部署
echo ""
./deployhost.sh $ip $sshport $user $pkgname $remote_tmpdir




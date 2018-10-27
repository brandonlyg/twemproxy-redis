#!/bin/sh
#在目标主机上部署python

cwd=$(cd $(dirname $0); pwd)

source ./common.sh

sname=$1
ip=$(gethost_ip $sname)
sshport=$(gethost_sshport $sname)
user=$(gethost_user $sname)

exp="\[\$#\]"

#检查主机上是否已经部署了
echo "check python on $ip"
res=$(expect << EOF
spawn ssh -p $sshport $user@$ip
expect $exp
send "\[ \-d ${python_home} \]; echo \"python-exist=\$?\"\n"
expect $exp
send "logout\n"
expect eof
EOF
)

res=$(echo "$res"|grep -e "^python-exist=[01]"|awk -F= '{ print $2 }')
res=${res:0:1}
if [ "0" = "$res" ]; then
    echo "python was deployed"
    exit 0
fi

#部署到远程主机
echo "copy python package to $ip"
scp -P $sshport ${distsdir}/python.tar.gz $user@$ip:${remote_tmpdir}

expect << EOF
spawn ssh -p $sshport $user@$ip
expect $exp
send "cd ${remote_tmpdir}; rm -rf python; tar -zxvf python.tar.gz \n"
expect $exp
send "mkdir -p ${python_home}; unalias cp; cp -rf python/* ${python_home}/ \n"
expect $exp
send "logout\n"
expect eof
EOF



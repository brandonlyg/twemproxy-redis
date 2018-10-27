#/bin/sh
#redis安装脚本

curip=$1

source ./install.conf

unalias cp

if [ ! -d "$twemproxy_home" ]; then
    mkdir -pv $twemproxy_home
    echo "copy twemproxy file to $twemproxy_home"
    cp -rf twemproxy/* ${twemproxy_home}/
else
    echo "twemproxy is exist"
fi



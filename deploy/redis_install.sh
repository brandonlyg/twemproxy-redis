#/bin/sh
#redis安装脚本

curip=$1

source ./install.conf

unalias cp

if [ ! -d "$redis_home" ]; then
    mkdir -pv $redis_home
    echo "copy redis file to $redis_home"
    cp -rf redis/* ${redis_home}/
else
    echo "redis is exist"
fi



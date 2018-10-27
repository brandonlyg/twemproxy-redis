#/bin/sh
#sentinel安装脚本

curip=$1

source ./install.conf

unalias cp

if [ ! -d $redis_home ]; then
    mkdir -pv $redis_home
    cp -rfv redis/* ${redis_home}/
fi

if [ -d "${sentinel_inshome}" ]; then
    ${sentinel_inshome}/bin/sentinel_shutdown.sh
    rm -rf ${sentinel_inshome}/*
else
    mkdir -pv ${sentinel_inshome}
fi

cp -rfv redis-sentinel-instances/* ${sentinel_inshome}/

${sentinel_inshome}/bin/sentinel_start.sh updateconfig

ins_res=successful
if [ "$?" != 0 ]; then
    ins_res=failed
else
    ins_res=successful
fi

echo "install redis sentinel $curip $ins_res"

#/bin/sh
#redis安装脚本

curip=$1

source ./install.conf

unalias cp

if [ ! -d "${redis_inshome}" ]; then
    #第一次安装
    mkdir -pv ${redis_inshome}
    cp -rfv redis-instances/* ${redis_inshome}/
    cp -fv redis_ins_confs/*.conf ${redis_inshome}/config
fi

cp -fv redis_ins_confs/${curip}/redis_${gname}-ins.conf ${redis_inshome}/config

${redis_inshome}/bin/redis_shutdown.sh ${gname}
${redis_inshome}/bin/redis_start.sh ${gname} updateconfig

ins_res=successful
if [ "$?" != 0 ]; then
    ins_res=failed
else
    ins_res=successful
fi

echo "install redis $curip ${ins_res}"

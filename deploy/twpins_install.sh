#/bin/sh
#twemproxy安装

curip=$1

source ./install.conf

unalias cp

if [ -d "$twemproxy_home" ]; then
    ${twemproxy_home}/sbin/shutdown.sh ${gname}
else
    mkdir -pv $twemproxy_home
fi

#安装redis-sentinel工具
rstool=redis-sentinel
rstooldir=${twemproxy_home}/tools/${rstool}
if [ ! -d "$rstooldir" ]; then
    mkdir -pv $rstooldir
    cp -rfv ${rstool}/* ${rstooldir}/
    ${rstooldir}/shutdown.sh
    ${rstooldir}/start.sh
fi

#copy twemproxy配置
cp -v ./insconfs/${curip}/* ${twemproxy_home}/conf/
${twemproxy_home}/sbin/start.sh ${gname}


ins_res=failed
if [ "$?" = "0" ]; then
    ins_res=successful
fi

echo "install twemproxy install $curip $ins_res"


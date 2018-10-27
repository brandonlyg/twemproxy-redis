#!/bin/sh
#创建twemproxy安装包

source ./common.sh
source ./configparser.sh

unalias cp
cwd=$(pwd)

pkgname=$1
pkgdir=$tmpdir/$pkgname
if [ -d "$pkgdir" ]; then
        rm -rf $pkgdir
        rm -rfv ${pkgdir}.zip
fi
mkdir $pkgdir

insconfdir=${pkgdir}/insconfs
mkdir -v $insconfdir

#把twemproxy实例的配置放到指定的目录下
for gname in $groups; do
    nodes=$(get_twemproxy_servers $gname)
    for nd in $nodes; do
        twip=$(gethost_ip $nd)

        confdir=${insconfdir}/${twip}
        if [ ! -d ${confdir} ]; then
            mkdir -v $confdir
        fi

        num=0
        while [ $num -lt 100 ]; do
            confname=${gname}-${num}.yml
            twconf=${gendir}/twp_${confname}
            if [ ! -f $twconf ]; then
                break
            fi
            cp -v $twconf ${confdir}/$confname

            num=$(expr $num + 1)
        done

    done
done

#打包redis-sentinel工具
sentinel_nodes=$(get_sentinel_nodes)
sentinel_nodes=$(echo $sentinel_nodes|sed 's/ /,/g')

echo "copy twemproxy-redis-sentinel"
cp -rf $distsdir/twemproxy-redis-sentinel $pkgdir/redis-sentinel
echo "PYTHON=${python_home}/bin/python"|tee $pkgdir/redis-sentinel/env.sh
conf_file=$pkgdir/redis-sentinel/conf/twprs.conf
echo "twp_home=${twemproxy_home}"|tee ${conf_file}
echo "sentinels=${sentinel_nodes}"|tee -a ${conf_file}

#添加安装脚本
cp -v ./twpins_install.sh $pkgdir/install.sh
echo "twemproxy_home=${twemproxy_home}"|tee $pkgdir/install.conf

#打包
cd $tmpdir
/usr/bin/zip -r ${pkgname}.zip $pkgname

cd $cwd


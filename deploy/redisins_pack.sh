#!/bin/sh
#创建redis安装包

source ./common.sh

unalias cp

pkgname=$1

pkgdir=${tmpdir}/${pkgname}
echo "pkgdir $pkgdir"
if [ -d "$pkgdir" ]; then
	rm -rf $pkgdir
	rm -rfv ${pkgdir}.zip
fi

mkdir $pkgdir

echo "copy redis-instances"
cp -rf $distsdir/redis-instances $pkgdir/
rm -rf $pkgdir/redis-instances/config/*

cp -rfv $gendir/redis_ins_confs $pkgdir/
cp -v $configdir/redis.conf $pkgdir/redis_ins_confs/redis_parameters.conf

cp -v ./redisins_install.sh $pkgdir/install.sh
echo "redis_home=${redis_home}" |tee $pkgdir/install.conf
echo "redis_inshome=${redis_inshome}" |tee -a $pkgdir/install.conf

cd $tmpdir
/usr/bin/zip -r ${pkgname}.zip $pkgname

cd ..
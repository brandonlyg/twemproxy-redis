#!/bin/sh
#创建redis安装包

source ./common.sh

unalias cp

pkgname=$1
pkgdir=$tmpdir/$pkgname
if [ -d "$pkgdir" ]; then
	rm -rf $pkgdir
	rm -rf ${pkgdir}.zip
fi
mkdir $pkgdir

echo "copy redis-instance"
cp -rf $distsdir/redis-instances $pkgdir/redis-sentinel-instances
rm -rf $pkgdir/redis-sentinel-instances/config/*

cp -v  $gendir/sentinel.conf $pkgdir/redis-sentinel-instances/config/
cp -v  $gendir/sentinel_monitor.conf $pkgdir/redis-sentinel-instances/config/

cp -v ./redis_sentinel_install.sh $pkgdir/install.sh
echo "redis_home=${redis_home}" |tee $pkgdir/install.conf
echo "sentinel_inshome=${sentinel_inshome}" |tee -a $pkgdir/install.conf

cd $tmpdir
echo "start pack $pkgname"
/usr/bin/zip -rq ${pkgname}.zip $pkgname

cd ..
#!/bin/sh
#创建redis安装包

source ./common.sh

unalias cp

pkgname=$1
update=$2

pkgdir=${tmpdir}/${pkgname}
echo "pkgdir $pkgdir"
if [ "$update" == "updata" ]; then
    rm -rf $pkgdir
	rm -rfv ${pkgdir}.zip
fi

rebuild="false"

if [ ! -f "${pkgdir}.zip" ]; then
    rebuild="true"
fi

if [ "$rebuild" == "false" ]; then
    echo "package ${pkgdir}.zip is exists"
    exit 0
fi

if [ -d "$pkgdir" -o "$update" = "update" ]; then
	rm -rf $pkgdir
	rm -rfv ${pkgdir}.zip
fi

if [ -d "$pkgdir" ]; then
    rm -rf $pkgdir
fi

if [ -f "${pkgdir}.zip" ]; then
    rm -rfv ${pkgdir}.zip
fi

mkdir $pkgdir

echo "copy twemproxy"
cp -rf $distsdir/twemproxy ${pkgdir}/
rm -rf ${pkgdir}/twemproxy/conf/*
cp -v ./twp_install.sh ${pkgdir}/install.sh
echo "twemproxy_home=${twemproxy_home}" |tee $pkgdir/install.conf

cd $tmpdir
/usr/bin/zip -r ${pkgname}.zip $pkgname

cd ..
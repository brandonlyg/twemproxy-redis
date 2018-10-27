#!/usr/bin/expect
#部署一台主机

set destip [lindex $argv 0]
set sshport [lindex $argv 1]
set user [lindex $argv 2]
set pkgname [lindex $argv 3]
set tmpdir [lindex $argv 4]

set exp "\[$#\]"

spawn ssh -p $sshport $user@$destip
expect "$exp"
send "cd $tmpdir; rm -rf $pkgname; unzip ${pkgname}.zip\n"
expect "$exp"
send "cd $pkgname; ./install.sh $destip\n"
expect "$exp"
send "logout\n"
interact


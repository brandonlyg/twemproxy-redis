#!/usr/bin/expect
#初始化redis主机环境

set destip [lindex $argv 0]
set sshport [lindex $argv 1]
set user  [lindex $argv 2]
set tmpdir [lindex $argv 3]

set exp "\[$#\]"

spawn ssh -p $sshport $user@$destip
expect "$exp"
send "mkdir $tmpdir\n"
expect "$exp"
send "logout\n"
interact


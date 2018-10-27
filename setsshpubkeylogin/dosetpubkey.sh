#!/usr/bin/expect
#设置一台主机的pubkey

set timout 30

set ip [lindex $argv 1]
set port [lindex $argv 2]
set user [lindex $argv 3]
set password [lindex $argv 4]

spawn ssh-copy-id $user@$ip -p $port
expect {
	"(yes/no)?" {send "yes\n"; exp_continue}
	"password:" {send "${password}\n"; exp_continue}
	"added."
}



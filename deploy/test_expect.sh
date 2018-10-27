#!/bin/sh

ip=172.20.183.190
user=kduser
res=""
exp="\[\$#\]"


res=$(expect << --EOF
spawn ssh $user@$ip
expect $exp
send "\[ \-d ~/.local/python \]; echo \"python-exist=\$?\"\n"
expect $exp
send "logout\n"
expect eof
--EOF
)

echo $res

res=$(echo "$res"|grep -e "^python-exist=[01]"|awk -F= '{ print $2 }')
res=${res:0:1}
echo "the result is -${res}--"
if [ "$res" = "0" ]; then
    echo "python exists"
fi
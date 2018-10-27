#!/bin/sh
#设置ssh pubkey 登录

hostsconf=$1

while read data; do
	if [ -z "$data" ]; then
		continue
	fi
	comment=$(echo $data|grep -e "^#.*")
	if [ -n "$comment" ]; then
		continue
	fi

	#password=$(echo $data|awk '{ print $4 }')
	
	echo $data	
	./dosetpubkey.sh $data
	
done < $hostsconf


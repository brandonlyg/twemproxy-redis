#!/bin/sh

#根据key得到指定val
function get_property(){
	profile=$1
	pkey=$2

	if [ -z "$pkey" ]; then
        	echo ""
        	exit 0
	fi

	#echo "read file"
	while read data; do
        	key=`echo $data|awk -F= '{ print $1 }'`
        	val=`echo $data|awk -F= '{ print $2 }'`
        	if [ "$key" = "$pkey" ]; then
                	echo "$val"
			break
        	fi
	done < $profile	
}

#根据key的前缀,得到多个key=val 对
function get_multi_property_pair(){
	profile=$1
	prefixKey=$2
	
	#echo "$prefixKey"	
	if [ -z "$prefixKey" ]; then
                echo ""
                exit 0
        fi
	regKey=$(echo "$prefixKey"|sed 's/\./\\./g')

        #echo "read file"
	res=""
        while read data; do
		if [ -z "$data" ]; then
			continue
		fi
		comment=$(echo "$data"|grep -e "^#.*")
		if [ -n "$comment" ]; then
			continue
		fi
		#echo "$data"		

                key=`echo $data|awk -F= '{ print $1 }'`
		val=$(echo "$data"|awk -F= '{ print $2 }')		

		ismatch=$(echo "$key"|grep -e "^${regKey}.*")
		if [ -z "$ismatch" ]; then
			continue
		fi
		
		prelen=$(echo ${#prefixKey})
		key=$(echo ${key:$prelen})
		if [ -n "$key" ]; then
			key=$(echo ${key:1})
		fi
		if [ -z "$key" ]; then
			key="."
		fi
		
		res="$res $key=$val"
		
        done < $profile	
	
	echo $res
}




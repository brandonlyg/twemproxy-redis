#!/bin/sh

source ./common.sh

#procount=$(./loadconf.sh test.redis.processes)
#echo $procount

echo "procount"
get_redis_processes test s02
get_redis_processes test s04
get_redis_processes test1 s01

source ./configparser.sh

echo "twemproxy nodes:"
get_twemproxy_nodes test

echo -e "\nredis nodes"
get_redis_nodes test
echo ""

declare -A map=(["111"]="111", ["222"]="22222")

map["111"]="111-1"

for k in ${!map[@]}; do
    echo "$k = ${map[$k]}"
done


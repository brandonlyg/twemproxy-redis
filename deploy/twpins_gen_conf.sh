#!/bin/sh
#生成twemproxy 配置

gname=$1

source ./common.sh

function redis_master_nodeinfo(){
    local gname=$1

    local rmnodes=$(get_redis_servers ${gname} master)
    local rport=$(loadconf ${gname}.redis.port)

    local nodeinfo=""
    for sname in $rmnodes; do
        local mip=$(gethost_ip $sname)
        local pcount=$(get_redis_processes $gname $sname)
        local nodeport=$rport

        local pn=0
        while [ "$pn" -lt "$pcount" ]; do
            nodeinfo="$nodeinfo ${mip}:${nodeport}"

            nodeport=$(expr ${nodeport} + 1)
            pn=$(expr $pn + 1)
        done
    done

    echo $nodeinfo
}


twemconf="$gendir/twp_${gname}-0.yml"
if [ -f $twemconf ]; then
    rm $twemconf
fi
echo "gen $twemconf"

redisauth=$(loadconf ${gname}.redis.option.requirepass)
twemport=$(loadconf ${gname}.twemproxy.port)

echo "current:" |tee -a $twemconf
echo "  listen: 0.0.0.0:${twemport}" |tee -a $twemconf
echo "  hash: fnv1a_64" |tee -a $twemconf
echo "  distribution: ketama" |tee -a $twemconf
echo "  redis: true" |tee -a $twemconf
if [ -n "$redisauth" ]; then
    echo "  redis_auth: $redisauth" |tee -a $twemconf
fi
echo "  servers:" |tee -a $twemconf

redisnodes=$(redis_master_nodeinfo $gname)

snum=1
for snode in $redisnodes; do
    echo "   - ${snode}:1 server_${snum}" |tee -a $twemconf
    snum=$(expr $snum + 1)
done

process=$(loadconf ${gname}.twemproxy.processes)
pnum=1
port=$(expr $twemport + 2)
while [ $pnum -lt "$process" ]; do
    conf="$gendir/twp_${gname}-${pnum}.yml"
    if [ -f "$conf" ]; then
        rm $conf
    fi
    echo "gen $conf"
    sed "s/0.0.0.0:${twemport}/0.0.0.0:${port}/" $twemconf | tee -a $conf
    pnum=$(expr $pnum + 1)
    port=$(expr $port + 2)
done





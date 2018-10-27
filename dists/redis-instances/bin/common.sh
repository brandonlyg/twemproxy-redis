#!/bin/sh

function get_ins_confs(){
    local gname=$1
    if [ "$gname" = "all" ]; then
        gname=''
    fi

    local confs=$(ls config|grep -P 'redis_(\w+)\-ins.conf')
    local fnames=""
    for fname in $confs; do
        curgname=$(echo ${fname}|sed -r 's/redis_|\-ins\.conf//g')
        if [ -n "$gname" ]; then
            if [ "$curgname" != "$gname" ]; then
                continue
            fi
        fi

        fnames="${fnames}${fname} "
    done

    echo -n "$fnames"
}
#!/bin/sh

source ./common.sh

declare -A twpsvrs2group=()

function get_twempsvr2group(){
    local gname
    for gname in $groups; do
        local nodes=$(get_twemproxy_servers $gname)
        for nd in $nodes; do
            local tmp=${twpsvrs2group["$nd"]}
            twpsvrs2group["$nd"]="${tmp}${gname} "
        done
    done

}
function get_all_servers(){
    get_twempsvr2group
    local servers=""
    for nd in ${!twpsvrs2group[@]}; do
        servers="${servers}${nd} "
    done
    echo "$servers"
}



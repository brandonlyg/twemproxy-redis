# coding=utf-8

import os
import logging
from utils import easylog
import twemproxynode
import redisnode

log = None

def checkres_tostring(res):
    resstr = ""
    okformat = "% 5s % 45s % 24s % 9s % 14s % 10s"
    errformat = "% 5s % 54s % 54s"
    for ginfo in res:
        resstr = resstr + "group: %s\n" % ginfo['group']

        strok = (okformat+"\n") % (
            'state', 'nodes', 'memory', 'clients', 'ops_per_sec', 'keys'
        )
        strerr = (errformat+"\n") % (
            'state', 'node0', 'node1'
        )

        total_ops_per_sec = 0
        total_keys = 0
        for ndinfo in ginfo['nodes']:
            if 'OK' == ndinfo['state']:
                nodes = ndinfo['nodes']
                strnodes = "%s:%d-%s:%d" % (
                    nodes['master']['host'], nodes['master']['port'],
                    nodes['slave']['host'], nodes['slave']['port']
                )
                memory = ndinfo['memory']
                strmemory = "%s/%s" % (memory['used'], memory['max'])

                txt = (okformat + "\n") % (
                    ndinfo['state'], strnodes, strmemory,
                    str(ndinfo['clients']), str(ndinfo['ops_per_sec']),
                    str(ndinfo['keys'])
                )
                total_ops_per_sec += ndinfo['ops_per_sec']
                total_keys += ndinfo['keys']

                strok = strok + txt
            else:
                txt = (errformat + "\n") % (
                    ndinfo['state'],
                    erronode_tostring(ndinfo['node0']),
                    erronode_tostring(ndinfo['node1'])
                )

                strerr = strerr + txt

        strok = strok + "total  ops_per_sec:%d keys:%d\n" % (total_ops_per_sec, total_keys)

        resstr = resstr + strok + strerr + "\n"

    return resstr


def erronode_tostring(nd):
    # log.info(nd)
    rtrole = 'slave'
    if nd['role'] == 'slave':
        rtrole = 'master'
    elif nd['role'] == 'master':
        rtrole = 'slave'
    else:
        rtrole = 'None'

    addr = None
    if 'None' != rtrole:
        addr = nd[rtrole]

    if addr is None:
        addr = {'host':'', 'port':0}

    strnd = "%s:%d,%s,%s=%s:%d" % (
        nd['itself']['host'], nd['itself']['port'],
        str(nd['role']),
        rtrole, addr['host'], addr['port']
    )

    return strnd


def main():
    global log

    logpath = "./logs"
    if not os.path.exists(logpath):
        os.mkdir(logpath)

    logpath = logpath + "/monitor.log"

    logconfig={
        'level': logging.INFO,
        'filepath': logpath,
        'maxBytes': 100 * 1024 * 1024,
        'backupCount': 5
    }


    easylog.init_logging(logconfig)

    log = logging.getLogger(__name__)

    twemproxynode.check_twemproxy_nodes()

    res = redisnode.check_redis_nodes()
    resstr = checkres_tostring(res)
    log.info(resstr)

    '''
    twnodes = common.get_twemproxy_nodes()

    for group in twnodes:
        nodes = twnodes[group]
        check_twemproxy_nodes(group, nodes)
    
    '''


if __name__ == "__main__":
    main()
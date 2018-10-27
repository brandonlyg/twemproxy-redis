# coding=utf-8

import os
import logging
import rediswrapper

'''
created by brandon 2018-07-13
公共函数
'''

log = logging.getLogger(__name__)

configdir="../config"
deployconf=configdir+"/deploy.conf"
hostconf=configdir+"/hosts.conf"

shellcode="cd ../deploy; source ./configparser.sh;"

tmpdir = "tmp"
twnodesfpath = tmpdir + "/twemproxynods.cache"
redisnodesfpath = tmpdir + "/redisnods.cache"

# 得到twemproxy的服务器节点
def get_twemproxy_nodes():
    twnodes = get_twemproxy_nodes_fromcache()
    if twnodes is None:
        twnodes = get_twemproxy_nodes_fromconf()

    return twnodes

def get_twemproxy_nodes_fromconf():
    shellcmd=shellcode+"echo -n ${groups}"
    res = os.popen(shellcmd).read()
    groups = res.split(' ')

    twnodes = {}
    data = ""
    for gname in groups:
        shellcmd = shellcode + "get_twemproxy_nodes " + gname
        res = os.popen(shellcmd).read()

        data = data + gname + " " + res + "\n"

        nodes = res.split(' ')
        gnodes = []
        for node in nodes:
            nodearr = node.split(":")
            rnd = rediswrapper.RedisNode(nodearr[0], int(nodearr[1]), nodearr[2])
            gnodes.append(rnd)

        twnodes[gname] = gnodes

    if not os.path.exists(tmpdir):
        os.mkdir(tmpdir)

    if os.path.exists(twnodesfpath):
        os.remove(twnodesfpath)

    f = open(twnodesfpath, 'w')
    f.write(data)
    f.close()

    return twnodes

def get_twemproxy_nodes_fromcache():
    if not os.path.exists(twnodesfpath):
        return None

    fst1 = os.stat(deployconf)
    # modifyt = fst[8]
    fst2 = os.stat(twnodesfpath)
    if fst2[8] < fst1[8]:
        os.remove(twnodesfpath)
        return None

    twnodes = {}
    f = open(twnodesfpath, 'r')
    for line in f.readlines():
        ll = len(line)
        line = line[0:(ll - 1)]

        nodes = line.split(' ')
        gname = nodes[0]
        gnodes = []
        for i in range(len(nodes)):
            if 0 == i:
                continue
            node = nodes[i]
            nodearr = node.split(":")
            rnd = rediswrapper.RedisNode(nodearr[0], int(nodearr[1]), nodearr[2])
            gnodes.append(rnd)

        twnodes[gname] = gnodes

    return twnodes


# 得到redis的服务器节点
def get_redis_nodes():
    redisnodes = get_redis_nodes_fromcache()
    if redisnodes is None:
        redisnodes = get_redis_nodes_fromconf()

    return redisnodes

def get_redis_nodes_fromconf():
    shellcmd=shellcode+"echo -n ${groups}"
    res = os.popen(shellcmd).read()
    groups = res.split(' ')

    redisnodes = {}
    data = ""
    for gname in groups:
        shellcmd = shellcode + "get_redis_nodes " + gname
        res = os.popen(shellcmd).read()
        nodes = res.split(' ')

        data = data + gname + " " + res + "\n"

        gnodes = []
        for pair in nodes:
            arrpair = pair.split('-')
            nd0 = arrpair[0]
            nd1 = arrpair[1]

            nodepair = []

            arrnd = nd0.split(':')
            rnd = rediswrapper.RedisNode(arrnd[0], int(arrnd[1]), arrnd[2])
            nodepair.append(rnd)

            arrnd = nd1.split(':')
            rnd = rediswrapper.RedisNode(arrnd[0], int(arrnd[1]), arrnd[2])
            nodepair.append(rnd)

            gnodes.append(nodepair)

        redisnodes[gname] = gnodes


    if os.path.exists(redisnodesfpath):
        os.remove(redisnodesfpath)

    f = open(redisnodesfpath, "w")
    f.write(data)
    f.close()

    return redisnodes

def get_redis_nodes_fromcache():
    if not os.path.exists(redisnodesfpath):
        return None

    fst1 = os.stat(deployconf)
    # modifyt = fst[8]
    fst2 = os.stat(redisnodesfpath)
    if fst2[8] < fst1[8]:
        os.remove(redisnodesfpath)
        return None

    redisnodes = {}
    f = open(redisnodesfpath, 'r')
    for line in f.readlines():
        ll = len(line)
        line = line[0:(ll - 1)]

        nodes = line.split(' ')
        gname = nodes[0]

        gnodes = []
        for i in range(len(nodes)):
            if 0 == i:
                continue

            pair = nodes[i]
            arrpair = pair.split('-')
            nd0 = arrpair[0]
            nd1 = arrpair[1]

            nodepair = []

            arrnd = nd0.split(':')
            rnd = rediswrapper.RedisNode(arrnd[0], int(arrnd[1]), arrnd[2])
            nodepair.append(rnd)

            arrnd = nd1.split(':')
            rnd = rediswrapper.RedisNode(arrnd[0], int(arrnd[1]), arrnd[2])
            nodepair.append(rnd)

            gnodes.append(nodepair)

        redisnodes[gname] = gnodes

    return redisnodes

def get_redis_roles(pair):
    roles = {}
    for nd in pair:
        info = None
        try:
            info = nd.get_redis().info()
        except Exception as e:
            log.info("execute info error: %s:%d", nd.host, nd.port)
            log.exception(e)
            continue

        if 'master' == info['role']:
            master = {
                'node': nd,
            }
            if 'slave0' in info:
                slave0 = info['slave0']
                master['slave'] = {
                    'host': slave0['ip'],
                    'port': int(slave0['port'])
                }
            roles['master'] = master
        elif 'slave' == info['role']:
            slave = {
                'node': nd
            }
            slave['master'] = {
                'host': info['master_host'],
                'port': int(info['master_port'])
            }
            roles['slave'] = slave

    return roles


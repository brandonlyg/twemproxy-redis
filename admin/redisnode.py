# coding=utf-8

import logging
import common
'''
created by brandon 2018-07-16
检查redis节点的主备关系及twemproxy配置
'''

log = logging.getLogger(__name__)

# 检查索引redis节点
def check_redis_nodes():
    log.info("load redis node config")
    nodes = common.get_redis_nodes()

    checkres = []
    for gname in nodes:
        gnodes = nodes[gname]
        res = check_redis_group(gname, gnodes)
        checkres.append(res)

    return checkres


'''
检查指定group的redis
检查结果格式
节点状态正确的格式 
{ 'state':'OK', 
'nodes':{'master':{host:'', port:1}, 'slave':{'host':'', port:1}, 
'memory':{'used': '100M', 'max':'1000M'}
'clients': 10
'ops_per_sec': 100
'keys': 111
}
节点状态错误的格式
{ 'state': 'ERROR', 
  'node0': {'itself':{'host':'', port:1}, 'role':'master', 'slave':{'host':'', port:1}},
  'node1': {'itself':{'host':'', port:1}, 'role':'slave', 'master':{'host':'', port:1}}  
}
'''
def check_redis_group(gname, nodes):
    checkres = {
        'group': gname,
        'nodes': []
    }

    for pair in nodes:
        nd0 = pair[0]
        nd1 = pair[1]

        info0 = None
        info1 = None
        try:
            info0 = nd0.get_redis().info()
            info0['code'] = 0
        except Exception, e:
            info0 = {}
            info0['code'] = 1

        try:
            info1 = nd1.get_redis().info()
            info1['code'] = 0
        except Exception, e:
            info1 = {}
            info1['code'] = 1

        info0['address'] = {'host':nd0.host, 'port':nd0.port}
        info1['address'] = {'host':nd1.host, 'port':nd1.port}

        res = {}
        if info0['code'] == 0 and info1['code'] == 0:
            res = check_master_slave_reltive(info0, info1)
        else:
            res['state'] = 'ERROR'

        res = get_node_info(res, info0, info1)

        checkres['nodes'].append(res)


    return checkres


# 得到节点的信息
def get_node_info(res, info0, info1):
    if 'OK' == res['state']:
        master = info0
        maddr = res['nodes']['master']

        addr1 = info1['address']
        if maddr['host'] == addr1['host'] and maddr['port'] == addr1['port']:
            master = info1

        res['memory'] = {
            'used': master['used_memory_human'],
            'max': master['maxmemory_human']
        }

        res['clients'] = master['connected_clients']
        res['ops_per_sec'] = master['instantaneous_ops_per_sec']
        res['keys'] = 0
        if master.has_key('db0'):
            res['keys'] = master['db0']['keys']
    else:
        res['node0'] = get_err_node_info(info0)
        res['node1'] = get_err_node_info(info1)

    return res


def get_err_node_info(info):
    res = {}
    res['itself'] = info['address']
    if info['code'] != 0:
        info['role'] = None

    res['role'] = info['role']
    if res['role'] is None:
        return res

    if 'master' == info['role']:
        res['slave'] = None
        if info.has_key('slave0'):
            slave = info['slave0']
            res['slave'] = {
                'host': slave['ip'],
                'port': slave['port']
            }
    elif 'slave' == info['role']:
        res['master'] = {
            'host': info['master_host'],
            'port': info['master_port']
        }

    return res


# 检查两个redis的主-备关系
def check_master_slave_reltive(info0, info1):
    res = None
    if 'master' == info0['role'] and 'slave' == info1['role']:
        res = check_master_slave(info0, info1)
    elif 'master' == info1['role'] and 'slave' == info0['role']:
        res = check_master_slave(info1, info0)
    else:
        res = {'state':'ERROR'}

    return res

# 检查两个redis的主备关系是否正确
def check_master_slave(master, slave):
    m_addr = master['address']
    # log.info(m_addr)
    s_addr = slave['address']
    # log.info(s_addr)

    #log.info(master['slave0'])
    res = {
        'state': 'ERROR'
    }

    if not master.has_key('slave0'):
        return res

    m_slave = master['slave0']
    if m_slave is None:
        return res

    if not (m_slave['ip'] == s_addr['host'] and m_slave['port'] == s_addr['port']):
        return res

    m_host = slave['master_host']
    m_port = int(slave['master_port'])
    if not (m_host == m_addr['host'] and m_port == m_addr['port']):
        return res

    res['state'] = 'OK'
    res['nodes'] = {
        'master': m_addr,
        'slave': s_addr
    }

    return res



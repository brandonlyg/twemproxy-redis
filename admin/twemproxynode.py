# coding=utf-8

'''
created by brandon 2018-07-13
检查twemproxy 运行情况
'''

import sys, logging
import common
from rediswrapper import RedisNode

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(levelname)s %(asctime)s:] %(message)s')

log = logging.getLogger(__name__)

def check_twemproxy_nodes():
    nodes = common.get_twemproxy_nodes()
    for gname in nodes:
        gnode = nodes[gname]
        check_twemproxy_group(gname, gnode)



'''检查一个group中的所有twemproxy节点
一个节点写，所有的节点读, 读写数据一致表示这个group的节点没问题
'''
def check_twemproxy_group(group, nodes):
    log.info("start check twemproxy %s", group)

    # 生成写入的样本数据
    wdatas = {}
    wcount = 100
    for i in range(wcount):
        key = "testkey_%d" % i
        val = "this is test value %d" % i
        wdatas[key] = val

    keys = wdatas.keys()

    isOK = True
    ndcount = len(nodes)
    for idx in range(ndcount):
        nd_w = nodes[idx]
        strwnode = "%s:%d" % (nd_w.host, nd_w.port)

        # 写数据
        res = False
        try:
            rc_w = nd_w.get_redis()
            res = rc_w.mset(**wdatas)
            log.info("write to %s res: %s", strwnode, res)
        except Exception, e:
            log.info("write to %s error. %s", strwnode, e.message)
            res = False

        if not res:
            isOK = False
            log.error("twemproxy %s %s, write faild", group, strwnode)
            break

        # 读数据，并比较
        for i in range(ndcount):
            nd_r = nodes[i]
            strrnode = "%s:%s" % (nd_r.host, nd_r.port)

            rc_r = nd_r.get_redis()
            res = rc_r.mget(keys)
            isequal = True
            for j in range(len(keys)):
                key = keys[j]
                val = res[j]
                if val != wdatas[key]:
                    isequal = False
                    break

            if not isequal:
                isOK = False
                log.error("read from %s data is not equal", strrnode)
                break

        # 删除数据
        rc_w.delete(*keys)

    if isOK:
        log.info("check group %s OK", group)


if __name__ == '__main__':
    group = sys.argv[1]
    passwd = sys.argv[2]
    addrs = sys.argv[3]

    arr = addrs.split(",")
    nodes = []
    for i in range(len(arr)):
        str = arr[i]
        tmpaddr = str.split(":")
        host = tmpaddr[0]
        port = int(tmpaddr[1])
        nd = RedisNode(host, port, passwd)
        nodes.append(nd)

    check_twemproxy_group(group, nodes)


# coding=utf-8

import os
import logging
import common

logformat = "[%(levelname)s %(asctime)s %(filename)s %(lineno)d] %(message)s"

logging.basicConfig(level=logging.INFO, format=logformat)

log = logging.getLogger(__name__)

#res = os.system("cd ../deploy; ./twemproxy_gen_conf.sh > /dev/null")
#print("res %s" % res)

res = os.popen("echo -n 111:1,222:2,333:3").read()
print("res %s" % res)

res = os.popen("cd ../deploy; source ./configparser.sh; get_twemproxy_nodes test").read()
print(res)

nodes = common.get_twemproxy_nodes()

log.info("twemproxy nodes:")
for gname in nodes:
    logstr = "group: %s\n" % gname
    rnodes = nodes[gname]
    for nd in rnodes:
        ndstr = "host:%s port:%d password:%s\n" % (nd.host, nd.port, nd.password)
        logstr = logstr + ndstr

    log.info(logstr)


log.info("redis nodes:")
nodes = common.get_redis_nodes()
#log.info(nodes)
for gname in nodes:
    logstr = "group: %s\n" % gname
    gnodes = nodes[gname]
    for pair in gnodes:
        nd0 = pair[0]
        nd1 = pair[1]
        ndstr = "%s:%d:%s-%s:%d:%s\n" % (nd0.host, nd0.port, nd0.password,
                                         nd1.host, nd1.port, nd1.password)
        logstr = logstr + ndstr

    log.info(logstr)



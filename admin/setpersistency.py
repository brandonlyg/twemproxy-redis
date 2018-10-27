# coding=utf-8
# 设置master不刷盘， slave appendonly

import logging
import common

logging.basicConfig(level=logging.INFO, format='[%(levelname)s %(asctime)s:] %(message)s')

log = logging.getLogger(__name__)


def main():
    log.info("start set persistency")

    nodes = common.get_redis_nodes()

    checkres = []
    for gname in nodes:
        gnodes = nodes[gname]

        for pair in gnodes:
            roles = common.get_redis_roles(pair)

            rewrite = False
            if "master" in roles:
                master = roles['master']
                nd = master['node']
                try:
                    res = nd.get_redis().config_get("save")
                    if res is not None and res['save'] != '':
                        log.warn("master(%s:%d) save: %s", nd.host, nd.port, str(res))
                        nd.get_redis().config_set("save", "")
                        rewrite = True

                    res = nd.get_redis().config_get("appendonly")
                    if res is not None and res['appendonly'] != "no":
                        log.warn("master(%s:%d) appendonly: %s", nd.host, nd.port, str(res))
                        nd.get_redis().config_set("appendonly", "no")
                        rewrite = True

                    nd.get_redis().config_rewrite()
                except Exception as e:
                    log.error("execute config error. %s:%d", nd.host, nd.port)
                    log.exception(e)

            rewrite = False
            if "slave" in roles:
                slave = roles['slave']
                nd = slave['node']
                try:
                    res = nd.get_redis().config_get("save")
                    if res is not None and res['save'] != '':
                        log.warn("slave(%s:%d) save: %s", nd.host, nd.port, str(res))
                        nd.get_redis().config_set("save", "")
                        rewrite = False

                    res = nd.get_redis().config_get("appendonly")
                    if res is not None and res['appendonly'] != "yes":
                        log.warn("slave(%s:%d) appendonly: %s", nd.host, nd.port, str(res))
                        nd.get_redis().config_set("appendonly", "yes")
                        rewrite = False

                    nd.get_redis().config_rewrite()
                except Exception as e:
                    log.error("execute config error. %s:%d", nd.host, nd.port)
                    log.exception(e)


    log.info("end set persistency")


if __name__ == "__main__":
    main()

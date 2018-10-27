# coding=utf-8

# 主备强制主备切换，并设置刷盘

import logging
import redis

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG, format='[%(levelname)s %(asctime)s:] %(message)s')

log = logging.getLogger(__name__)

class MasterChangeSettingHandler(object):

    def onMasterChanged(self, oldIp, oldPort, newIp, newPort):
        passwd = "xtkingdee"
        try:
            rc_master = redis.Redis(host=newIp, port=newPort, password=passwd, socket_timeout=3, socket_connect_timeout=3)
            # rc_slave = redis.Redis(host=oldIp, port=oldPort, password=passwd, socket_timeout=3, socket_connect_timeout=3)

            data = rc_master.config_get("slaveof")['slaveof']
            if len(data) > 0:
                rc_master.slaveof()
                rc_master.config_set("save", "")
                rc_master.config_set("appendonly", "no")
                rc_master.config_rewrite()
                log.info("change %s:%d to master", newIp, newPort)

            '''
            data = rc_slave.config_get("slaveof")['slaveof']
            # log.info(data)
            arr = data.split(" ")
            changed = True
            if len(arr) == 2:
                ip = arr[0]
                port = int(arr[1])
                if ip == newIp or port == newPort:
                    changed = False

            if changed:
                rc_slave.slaveof(newIp, newPort)
                rc_master.config_set("save", "")
                rc_master.config_set("appendonly", "yes")
                rc_master.config_rewrite()
                log.info("change %s:%d to slave, master: %s:%d", oldIp, oldPort, newIp, newPort)
            '''

        except Exception as e:
            log.exception(e)


if __name__ == '__main__':
    handler = MasterChangeSettingHandler()

    handler.onMasterChanged("172.20.183.191", 6579, "172.20.183.190", 6579)




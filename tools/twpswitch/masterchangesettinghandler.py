# coding=utf-8

# 主备强制主备切换，并设置刷盘

import logging
import redis

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG, format='[%(levelname)s %(asctime)s:] %(message)s')

log = logging.getLogger(__name__)

class MainChangeSettingHandler(object):

    def onMainChanged(self, oldIp, oldPort, newIp, newPort):
        passwd = "xtkingdee"
        try:
            rc_main = redis.Redis(host=newIp, port=newPort, password=passwd, socket_timeout=3, socket_connect_timeout=3)
            # rc_subordinate = redis.Redis(host=oldIp, port=oldPort, password=passwd, socket_timeout=3, socket_connect_timeout=3)

            data = rc_main.config_get("subordinateof")['subordinateof']
            if len(data) > 0:
                rc_main.subordinateof()
                rc_main.config_set("save", "")
                rc_main.config_set("appendonly", "no")
                rc_main.config_rewrite()
                log.info("change %s:%d to main", newIp, newPort)

            '''
            data = rc_subordinate.config_get("subordinateof")['subordinateof']
            # log.info(data)
            arr = data.split(" ")
            changed = True
            if len(arr) == 2:
                ip = arr[0]
                port = int(arr[1])
                if ip == newIp or port == newPort:
                    changed = False

            if changed:
                rc_subordinate.subordinateof(newIp, newPort)
                rc_main.config_set("save", "")
                rc_main.config_set("appendonly", "yes")
                rc_main.config_rewrite()
                log.info("change %s:%d to subordinate, main: %s:%d", oldIp, oldPort, newIp, newPort)
            '''

        except Exception as e:
            log.exception(e)


if __name__ == '__main__':
    handler = MainChangeSettingHandler()

    handler.onMainChanged("172.20.183.191", 6579, "172.20.183.190", 6579)




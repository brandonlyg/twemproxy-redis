# coding=utf-8
# 通过订阅自定义redis命令，修复twemproxy配置，使用主动切换redis

import os, signal, sys, logging
from utils import easylog, deamons
import redis
from masterchangehandler import MasterChangeHandler
from masterchangesettinghandler import MasterChangeSettingHandler
isStart = False
log = None

twhome="~/.local/twemproxy"
redisaddr={'host':'172.20.178.26', 'port':6079, 'password':'xtkingdee'}

changerole=False

# 订阅redis切换命令
def subswitchcmd(handler):
    global isStart
    global redisaddr
    global changerole

    settinghandler = MasterChangeSettingHandler()

    while isStart:
        try:
            rc = redis.Redis(host=redisaddr['host'], port=redisaddr['port'], password=redisaddr['password'])
            pubsub = rc.pubsub()
            pubsub.subscribe(['switchmaster'])
            log.info("subscribe switchmaster")
            while pubsub.subscribed and isStart:
                res = pubsub.get_message(ignore_subscribe_messages=True, timeout=0.1)
                if res is None:
                    continue

                log.info(res)
                if not res.has_key("data"):
                    continue

                addrs = str(res["data"]).split(" ")

                for i in range(len(addrs)):
                    arr = addrs[i].split(":")
                    addr = {
                        'host': arr[0],
                        'port': int(arr[1])
                    }
                    addrs[i] = addr

                oldaddr = addrs[0]
                newaddr = addrs[1]

                if changerole:
                    settinghandler.onMasterChanged(oldaddr['host'], oldaddr['port'], newaddr['host'], newaddr['port'])

                handler.onMasterChanged(oldaddr['host'], oldaddr['port'], newaddr['host'], newaddr['port'])


        except:
            pass




def term_handler(signo, frame):
    log.info('recv signal %d' % signo)
    global isStart
    isStart = False


def main():
    global isStart
    global log
    global twhome
    global changerole

    changerole = False
    if len(sys.argv) > 1:
        strchangerole = sys.argv[1]
        if 'changerole' == strchangerole:
            changerole = True

    logpath = "logs"
    if not os.path.exists(logpath):
        os.mkdir(logpath)

    logfile = logpath + "/twpswitch.log"

    logconfig={
        'level': logging.INFO,
        'filepath': logfile,
        'maxBytes': 1024 * 1024 * 20,
        'backupCount': 5
    }

    easylog.init_logging(logconfig)
    log = logging.getLogger(__name__)

    deamons.run_as_deamon()

    signal.signal(signal.SIGTERM, term_handler)

    easylog.disable_consoleHandler()

    if twhome.startswith("~"):
        userhome = os.path.expanduser("~")
        twhome = twhome.replace('~', userhome)

    masterChangeHandler = MasterChangeHandler(twhome)
    masterChangeHandler.start()
    isStart = True

    log.info("twpswitch start. changerole:%s", str(changerole))
    subswitchcmd(masterChangeHandler)

    masterChangeHandler.stop()


if __name__ == '__main__':
    main()

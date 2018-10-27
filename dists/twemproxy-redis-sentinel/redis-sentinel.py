#coding=utf-8

from utils import easylog, deamons, properties
import signal
import time
import os
import logging
import twemsentinel
from masterchangehandler import MasterChangeHandler

isStart = False
log = None

def term_handler(signo, frame):
    log.info('recv signal %d' % signo)
    global isStart
    isStart = False

def main():
    global isStart
    global log

    logpath = "logs"
    if not os.path.exists(logpath):
        os.mkdir(logpath)

    logfile = logpath + "/redis-sentinel.log"

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

    ###

    pro = properties.load("conf/twprs.conf")

    twp_home = pro.get("twp_home")
    if twp_home.startswith("~"):
        userhome = os.path.expanduser("~")
        twp_home = twp_home.replace('~', userhome)

    log.info("twemproxy home: %s", twp_home)
    masterChangeHandler = MasterChangeHandler(twp_home)
    masterChangeHandler.start()


    strsentinels = pro.get("sentinels")
    sentinels = []
    arrsentinel = strsentinels.split(",")
    for straddr in arrsentinel:
        arraddr = straddr.split(":")
        addr = {
            "host": arraddr[0],
            "port": int(arraddr[1])
        }
        sentinels.append(addr)


    twems = twemsentinel.TwemSentinel(sentinels, masterChangeHandler)
    twems.start()

    ###

    pidfile = logpath + "/redis-sentinel.pid"
    if os.path.exists(pidfile):
        os.remove(pidfile)

    fd = open(pidfile, 'w')
    data = "%s" % os.getpid()
    fd.write(data)
    fd.close()

    log.info("redis-sentinel start")

    isStart = True
    while isStart:
        #log.info('running')
        try:
            time.sleep(1)
        except:
            pass

    masterChangeHandler.stop()
    twems.stop()

    log.info("process exit %d" % os.getpid())



if __name__ == '__main__':
    main()
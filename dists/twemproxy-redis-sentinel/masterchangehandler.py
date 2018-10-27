#coding=utf-8

import os
import threading
import Queue
import re
import logging
import yaml
import time
import glob

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG, format='[%(levelname)s %(asctime)s:] %(message)s')

log = logging.getLogger(__name__)

class MasterChangeHandler(threading.Thread):

    def __init__(self, twhome):
        threading.Thread.__init__(self)
        self.__eventQueue = Queue.Queue()
        self.__lock = threading.Lock()
        self.__twhome = twhome

        self.__isStart = True

    def run(self):
        self.__doHandlerEvent()

    def stop(self):
        self.__isStart = False

    def onMasterChanged(self, oldIp, oldPort, newIp, newPort):
        event = MaserChangeEvent(oldIp, oldPort, newIp, newPort)

        self.__putEvent(event)


    def __putEvent(self, event):
        self.__lock.acquire()

        try:
            self.__eventQueue.put(event);
        finally:
            self.__lock.release();

    def __getEvent(self):
        self.__lock.acquire()
        event = None
        try:
            event = self.__eventQueue.get(block=False)
        except:
            event = None
        finally:
            self.__lock.release()

        return event

    def __doHandlerEvent(self):
        while self.__isStart:
            event = self.__getEvent()
            if None == event:
                try:
                    time.sleep(0.1)
                except:
                    pass
                continue

            confs = self.__getTwemproxyConfigs()
            gchanged = {}
            for conf in confs:
                self.__updateTwemproxyConfig(conf, event)
                if conf.isChanged:
                    gchanged[conf.insName] = ""

            for gname in gchanged:
                self.__restartTwemproxy(gname)


    def __getTwemproxyConfigs(self):
        flist = glob.glob(self.__twhome + "/conf/*.yml")

        confs = []

        for fpath in flist:
            p = re.compile('.*/([\w\-_]+)\.yml')
            m = p.match(fpath)
            if None == m:
                log.warn("invalid file name:%s", fpath)
                continue

            groups = m.groups()
            if len(groups) <= 0:
                log.warn("invalid file name:%s", fpath)
                continue

            insName = groups[0]
            arr = insName.split("-")
            insName = arr[0]

            conf = TwemproxyConfig(fpath, insName)

            fd = None
            try:
                fd = open(fpath)
                proxyData = yaml.safe_load(fd)
                fd.close()
                conf.data = proxyData

            except:
                log.warn("Twemproxy config file could not open")
                if None != fd:
                    fd.close

                continue

            confs.append(conf)

        return confs



    def __updateTwemproxyConfig(self, conf, event):
        conf.isChanged = False
        proxyData = conf.data

        for proxy in proxyData:
            for i,server in enumerate(proxyData[proxy]["servers"]):
                serverinfo = server.split(" ")

                name=""
                if len(serverinfo) > 1:
                    name = serverinfo[1]

                '''
                try:
                    name = server.split(" ")[1]
                except:
                    pass
                '''
                hostinfo = serverinfo[0].split(":")

                host = hostinfo[0]
                port = hostinfo[1]
                number = hostinfo[2]

                if str(host) == str(event.oldIp) and str(port) == str(event.oldPort):
                    host = event.newIp
                    port = event.newPort

                    proxyData[proxy]["servers"][i]=host+":"+str(port)+":"+str(number)+" "+name
                    conf.isChanged = True

                    log.info('%s %s - %s:%s switch to %s:%s', conf.fpath, name, event.oldIp, event.oldPort, host, port)

        if conf.isChanged:
            fd = None
            try:
                fd = open(conf.fpath, "w")
                yaml.dump(proxyData, fd, default_flow_style=False)
                fd.close()
            except Exception, e:
                if None != fd:
                    fd.close()

                conf.isChanged = False
                log.warn('twemproxy config file could not update. %s %s', conf.fpath, e.message)


    def __restartTwemproxy(self, gname):
        cmd = self.__twhome + "/sbin/restart.sh %s" % gname
        log.info("restart command: %s", cmd)
        os.system(cmd)



class MaserChangeEvent(object):

    def __init__(self, oldIp, oldPort, newIp, newPort):
        self.oldIp      = oldIp
        self.oldPort    = oldPort
        self.newIp      = newIp
        self.newPort    = newPort


class TwemproxyConfig(object):
    def __init__(self, fpath, insName):
        self.fpath = fpath
        self.insName = insName
        self.data = None
        self.isChanged = False


if __name__ == '__main__':
    handler = MasterChangeHandler();

    handler.start()

    handler.onMasterChanged("10.247.10.173", 6480, "10.247.10.171", 6480)

    while True:
        time.sleep(1)
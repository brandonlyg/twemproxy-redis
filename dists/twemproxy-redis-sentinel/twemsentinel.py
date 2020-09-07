#coding=utf-8

import redis
import threading
import logging
import time
import random

log = logging.getLogger(__name__)

class TwemSentinel(threading.Thread):
    def __init__(self, sentinels, mainChangeHandler):
        threading.Thread.__init__(self)

        self.__isStart = True

        self.__sentinels = sentinels
        self.mainChangeHandler = mainChangeHandler;

        self.redis = None
        self.pubsub = None
        self.__connectSentinel()

    def __connectSentinel(self):
        idx = int(random.random() * 1001)
        #log.info("idx:%d", idx)
        idx = idx % len(self.__sentinels)

        addr = self.__sentinels[idx]

        try:
            log.info("connect sentinel %s:%d", addr['host'], addr['port'])
            self.redis = redis.StrictRedis(host=addr['host'], port=addr['port'])
            self.pubsub = self.redis.pubsub()
            self.pubsub.subscribe(['+switch-main'])
        except:
            log.warn("Redis sentinel connection error. %s:%d", addr['host'], addr['port'])
            self.redis = None
            self.pubsub = None

    def run(self):
        while self.__isStart:
            if self.redis is None:
                self.__connectSentinel()

            if self.redis is None:
                try:
                    time.sleep(1)
                except:
                    pass

                continue

            try:
                if self.pubsub.subscribed:
                    res = self.pubsub.get_message(ignore_subscribe_messages=True, timeout=0.1)
                    if res is None:
                        continue

                    log.info(res)
                    if not res.has_key("data"):
                        continue

                    sentinel = str(res["data"]).split(" ")
                    log.info(sentinel)
                    self.send(sentinel)

            except Exception, e:
                log.error("Redis pubsub error: %s", e.message)
                self.redis = None
                self.pubsub = None

    def stop(self):
        self.__isStart = False
        self.pubsub.unsubscribe()
        self.pubsub.punsubscribe()
        self.pubsub.close()
        self.join()
        log.info("thread twemsentinel exit")


    def send(self,sentinel):
        if len(sentinel) < 5:
            return

        oldIp = sentinel[1]
        oldPort = sentinel[2]
        newIp = sentinel[3]
        newPort = sentinel[4]

        log.info('main changed %s:%s to %s:%s', oldIp, str(oldPort), newIp, str(newPort))

        self.mainChangeHandler.onMainChanged(oldIp, oldPort, newIp, newPort);

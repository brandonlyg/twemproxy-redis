# coding=utf-8

import redis

'''
created by brandon 2018-07-17
redis客户端包装
'''


class RedisNode(object):

    def __init__(self, host, port, password):
        self.host = host
        self.port = port
        self.password = password

        self.__rc = None


    def get_redis(self):
        if self.__rc is not None:
            return self.__rc

        self.__rc = redis.Redis(host=self.host, port=self.port, password=self.password)

        return self.__rc
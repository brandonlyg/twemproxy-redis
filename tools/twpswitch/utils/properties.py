# coding=utf-8
'''
created by brandon 2018-06-28
properties 配置文件解析
'''

class Properties(object):

    def __init__(self):
        self.__data = {}


    def put(self, key, val):
        self.__data[key] = val


    def get(self, key):
        if not (key in self.__data):
            return None

        return self.__data[key]

    def get_by_prefix(self, prefix):
        res = {}
        for k in self.__data:
            val = self.__data[k]

            if not k.startswith(prefix):
                continue

            if len(k) < len(prefix) + 1:
                k = ""
            else:
                k = k[len(prefix) + 1:]

            res[k] = val

        return res

# 加载文件
def load(fpath):
    fd = open(fpath, 'r')

    pro = Properties()

    for line in fd:
        line = line.strip()
        if '' == line:
            continue

        if line.startswith('#'):
            continue

        arrs = line.split('=')
        pro.put(arrs[0].strip(), arrs[1].strip())

    return pro









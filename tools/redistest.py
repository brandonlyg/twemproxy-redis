# coding=utf-8

import sys, time, random
import redis

host=sys.argv[1]
port=int(sys.argv[2])
password=sys.argv[3]

rc = redis.Redis(host=host, port=port, password=password)

count = 100000
dlen = 1024

darr=['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']
strdata=""
for i in range(dlen):
    idx = random.randint(0,  15)
    strdata = strdata + darr[idx]


# test set
tstart = time.time()
for i in range(count):
    key = "str-%d" % i
    rc.set(key, strdata)

tend = time.time();
persec = count/(tend-tstart)
print("set persec:%d", persec)







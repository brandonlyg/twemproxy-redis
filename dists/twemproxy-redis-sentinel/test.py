# coding=utf-8

import glob
import os

res = os.path.expanduser("~")
print(res)

fpath = "~/workspace/redis/twemproxy-redis/dists/twemproxy"
if fpath.startswith("~"):
    fpath = fpath.replace('~', res)

print(fpath)
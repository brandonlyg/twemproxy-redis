# coding=utf-8

import sys
import redis

sentinelAddr = sys.argv[1]
cmdFile = sys.argv[2]

arrAddr = sentinelAddr.split(":")
host = arrAddr[0]
port = int(arrAddr[1])

#解析cmdFile
def parseCmdFile(fpath):
    state = 0

    cmds = []

    f = open(fpath, 'r')

    curCmd = None
    for line in f.readlines():
        line = line.replace("\r", "")
        line = line.replace("\n", "")

        if line.find("sentinel monitor") >= 0:
            if curCmd is not None:
                cmds.append(curCmd)

            arr = line.split(" ")
            curCmd = {}
            curCmd['monitor'] = {
                'name': arr[2],
                'ip': arr[3],
                'port': int(arr[4]),
                'num': int(arr[5])
            }
            curCmd['set'] = []
        elif line.find("sentinel set") >= 0:
            if curCmd is None:
                continue

            arr = line.split(" ")
            setCmd = {
                'name': arr[2],
                'option': arr[3],
                'value': arr[4]
            }
            curCmd['set'].append(setCmd)

    if curCmd is not None:
        cmds.append(curCmd)

    return cmds


cmds = parseCmdFile(cmdFile)

rc = redis.Redis(host=host, port=port)
print("set sentinel %s" % sentinelAddr)

for cmd in cmds:
    monitor = cmd['monitor']
    res = ""
    try:
        res = rc.sentinel_monitor(monitor['name'], monitor['ip'], monitor['port'], monitor['num'])
    except Exception, e:
        res = e.message

    print("monitor %s %s:%d %d res: %s" % (monitor['name'], monitor['ip'], monitor['port'], monitor['num'], str(res)))

    setCmds = cmd['set']
    for set in setCmds:
        res = rc.sentinel_set(set['name'], set['option'], set['value'])
        print("set %s %s %s res: %s" % (set['name'], set['option'], set['value'], str(res)))


print("--------------------------")



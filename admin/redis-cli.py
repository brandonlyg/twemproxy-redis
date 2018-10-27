# coding=utf-8

import sys
import common


def execute_command(node, cmd, args):
    try:
        res = ""
        if args is None:
            res = node.get_redis().execute_command(cmd)
        else:
            res = node.get_redis().execute_command(cmd, *args)

        print("%s:%d res %s" % (node.host, node.port, str(res)))
    except Exception, e:
        print(e)


def main():
    gname = sys.argv[1]
    role = sys.args[2]
    cmd = sys.argv[3]

    args = None
    if len(sys.argv) > 4:
        args = []
        idx = 4
        while idx < len(sys.argv):
            args.append(sys.argv[idx])
            idx += 1

    print("execute command to group:%s %s %s" % (gname, cmd, str(args)))

    nodes = common.get_redis_nodes()
    gnodes = nodes[gname]

    for pair in gnodes:
        nd0 = pair[0]
        nd1 = pair[1]

        if "master" == role or "all" == role:
            execute_command(nd0, cmd, args)
        elif "slave" == role or "all" == role:
            execute_command(nd1, cmd, args)


if __name__ == '__main__':
    main()



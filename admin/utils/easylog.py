#coding=utf-8
'''
Created on 2015年1月5日

@author: aa
'''

import logging
import logging.handlers


def init_logging(conf):

    logformat = "[%(levelname)s %(asctime)s %(filename)s %(lineno)d] %(message)s"

    logging.basicConfig(level=conf['level'], format=logformat)
    
    log = logging.getLogger()
    log.setLevel(logging.DEBUG)

    rh = logging.handlers.RotatingFileHandler(filename=conf['filepath'], maxBytes=conf['maxBytes'], backupCount=conf['backupCount'])
    fm = logging.Formatter(logformat)
    rh.setFormatter(fm)
    log.addHandler(rh)
    

def disable_consoleHandler():
    log = logging.getLogger()
    log.removeHandler(log.handlers[0])


if __name__ == '__main__':
    logconfig={
           'level': logging.DEBUG,
           'filepath': './test.log',
           'maxBytes': 200,
           'backupCount': 5
           }
    
    
    init_logging(logconfig)
    logging.debug('test debug')
    logging.info('test info')
    logging.warning('test warning')
    

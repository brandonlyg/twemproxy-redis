#coding=utf-8
'''
Created on 2015年1月6日

@author: aa
'''

import os
import sys
import signal
import time
import easylog
import logging

class NullDevice(object):
    
    def write(self, s):
        pass

def run_as_deamon():
    pid = os.fork()
    
    if pid:
        os._exit(0)
    
    #print('pid=%d' % os.getpid())
    
    os.setsid()
    
    pid = os.fork()
    if pid:
        os._exit(0)
    
    #print('pid=%d' % os.getpid())
    os.umask(0)
    
    sys.stdout = NullDevice()
    sys.stderr = NullDevice()
    
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    signal.signal(signal.SIGQUIT, signal.SIG_IGN)
    signal.signal(signal.SIGUSR1, signal.SIG_IGN)
    signal.signal(signal.SIGUSR2, signal.SIG_IGN)
    
if __name__ == '__main__':
    
    is_start = False
    
    def term_handler(signo, frame):
        print('recv signal %d' % signo)
        global is_start
        is_start = False
        
    logconfig={
           'level': logging.DEBUG,
           'filepath': './deamons.log',
           'maxBytes': 1024 * 1024 * 50,
           'backupCount': 5
           }
        
    easylog.init_logging(logconfig)
    
    logging.debug('pid=%d' % os.getpid())
    
    run_as_deamon()
    
    signal.signal(signal.SIGTERM, term_handler)
    
    logging.debug('pid=%d' % os.getpid())
    
    is_start = True
    
    logging.info('process start')
    
    easylog.disable_consoleHandler()
    
    while is_start:
        logging.info('running')
        time.sleep(1)
    
    logging.info("process exit %d" % os.getpid())


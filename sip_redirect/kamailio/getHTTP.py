# -*- coding: utf-8 -*-

"""
    HTTP Request to SmartRoute and set response to destination URI.
    Added:   2013-11-20: Created by: https://github.com/vitovitolo
"""

import httplib
from socket import timeout

class getHTTP:

    def __init__(self):
	pass

    def __del__(self):
	pass

    def child_init(self, rank):
	return 0

    def getHTTP(self, msg, req):
        #Parse request and get host and port because some bug parsing parameters to this method
        SERVER = req.split('/')[2].split(':')[0]
        PORT = req.split('/')[2].split(':')[1]
        TIMEOUT = 0.3
	REQUEST = req[req.find('/jizo')::]
        try:
           h1 = httplib.HTTPConnection(SERVER,PORT,timeout=TIMEOUT)
           h1.request('GET',REQUEST)
           response = h1.getresponse().read()
        except timeout:
           response = 'ERROR,SOCKET_TIMEOUT'
        except Exception as e:
           response = 'ERROR, {0}'.format(e)
        finally:
           h1.close()
           if (response=='None'):
               response = 'ERROR,UNKNOWN'
           #Set response to destination URI for further edit on Kamailio cfg script
           msg.set_dst_uri(response)
           return 1

def mod_init():
    return getHTTP()

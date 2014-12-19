import sys
import json
from tornado.httpclient import *
from tornado.concurrent import Future
from tornado import ioloop
from ryu.lib.packet import packet
import base64
from netkat.syntax import packet_in, packet_out

AsyncHTTPClient.configure("tornado.curl_httpclient.CurlAsyncHTTPClient")

async_client = AsyncHTTPClient()
sync_client = AsyncHTTPClient()

client_id = "default"

def pkt_out(switch, payload, actions, in_port = None):
    msg = packet_out(switch=switch, payload=payload,actions=actions,in_port=in_port)
    request = HTTPRequest("http://localhost:9000/pkt_out",
                          method='POST',
                          body=json.dumps(msg.to_json()))
    response = async_client.fetch(request)
    return

def update(policy):
    dict = { 'type' : 'policy',
             'data' : repr(policy) }
    request = HTTPRequest("http://localhost:9000/%s/update" % client_id,
                          method='POST',
                          body=json.dumps(dict))
    response = async_client.fetch(request)
    return

def event(handler):
    def f(response):
        if response.error:
            print response
        else:
            body = response.body
            handler(json.loads(body))
    request = HTTPRequest("http://localhost:9000/%s/event" % client_id,
                          method='GET',
                          request_timeout=float(0))
    response = sync_client.fetch(request, callback=f)
    return

def start():
    ioloop.IOLoop.instance().start()

def periodic(f,n):
    cb = ioloop.PeriodicCallback(f,n * 1000)
    cb.start()
    return

def event_loop(handler):
    def handler_(event) :
        handler(event)
        ioloop.IOLoop.instance().add_callback(loop)
    def loop():
        event(handler_)
    loop()

class App:
    def __init__(self):
        pass
    def switch_up(self,switch_id):
        pass
    def switch_down(self,switch_id):
        pass
    def port_up(self,switch_id, port_id):
        pass
    def port_down(self,switch_id, port_id):
        pass
    def packet_in(self, switch_id, port_id, payload):
        pass
    def start(self):
        def handler(event):
            print "EVENT: %s" % event
            typ = event['type']
            if typ == 'switch_up':
                switch_id = event['switch_id']
                self.switch_up(switch_id)
            elif typ == 'switch_down':
                switch_id = event['switch_id']
                self.switch_down(switch_id)
            elif typ == 'port_up':
                switch_id = event['switch_id']
                port_id = event['port_id']
                self.port_up(switch_id, port_id)
            elif typ == 'port_down':
                switch_id = event['switch_id']
                port_id = event['port_id']
                self.port_down(switch_id, port_id)
            elif typ == 'packet_in':
                pk = packet_in(event)
                self.packet_in(pk.switch_id, pk.port_id, pk.payload)
            else:
                pass
            ioloop.IOLoop.instance().add_callback(loop)
        def loop():
            event(handler)
        loop()

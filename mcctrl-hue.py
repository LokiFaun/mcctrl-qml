#!/usr/bin/python3
import time
import json
import random
import paho.mqtt.client as mqtt
from phue import Bridge

bridge_ip = '0.0.0.0'
mqtt_ip = '127.0.0.1'

bridge = Bridge(bridge_ip)
bridge.connect()


def on_connect(client, user_data, flags, rc):
    print('Connected with result code ' + str(rc))
    client.subscribe('mcctrl/cmd/lights/on')
    client.subscribe('mcctrl/cmd/lights/+/bri')
    client.subscribe('mcctrl/cmd/lights/+/on')
    client.subscribe('mcctrl/cmd/lights/+/clr')


def on_message(client, userdata, msg):
    print(msg.topic + ' ' + str(msg.payload))
    if (msg.topic == 'mcctrl/cmd/lights/on'):
        bridge.set_group(1, 'on', True if msg.payload == b'True' else False)
        client.publish('mcctrl/lights/on', bridge.get_group(1, 'on'))

    if (msg.topic == 'mcctrl/cmd/lights/1/bri'):
        bridge.set_light(1, 'bri', int(msg.payload))
        client.publish('mcctrl/lights/1/bri', bridge.get_light(1, 'bri'))
    if (msg.topic == 'mcctrl/cmd/lights/2/bri'):
        bridge.set_light(2, 'bri', int(msg.payload))
        client.publish('mcctrl/lights/2/bri', bridge.get_light(2, 'bri'))
    if (msg.topic == 'mcctrl/cmd/lights/3/bri'):
        bridge.set_light(3, 'bri', int(msg.payload))
        client.publish('mcctrl/lights/3/bri', bridge.get_light(3, 'bri'))

    if (msg.topic == 'mcctrl/cmd/lights/1/on'):
        bridge.set_light(1, 'on', True if msg.payload == b'True' else False)
        client.publish('mcctrl/lights/1/on', bridge.get_light(1, 'on'))
    if (msg.topic == 'mcctrl/cmd/lights/2/on'):
        bridge.set_light(2, 'on', True if msg.payload == b'True' else False)
        client.publish('mcctrl/lights/2/on', bridge.get_light(2, 'on'))
    if (msg.topic == 'mcctrl/cmd/lights/3/on'):
        bridge.set_light(3, 'on', True if msg.payload == b'True' else False)
        client.publish('mcctrl/lights/3/on', bridge.get_light(3, 'on'))

    if (msg.topic == 'mcctrl/cmd/lights/1/clr'):
        bridge.set_light(1, 'xy', json.loads(msg.payload))
    if (msg.topic == 'mcctrl/cmd/lights/2/clr'):
        bridge.set_light(2, 'xy', json.loads(msg.payload))
    if (msg.topic == 'mcctrl/cmd/lights/3/clr'):
        bridge.set_light(3, 'xy', json.loads(msg.payload))


client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect(mqtt_ip)
client.loop_start()

while (True):
    client.publish('mcctrl/lights/on', bridge.get_group(1, 'on'))
    client.publish('mcctrl/lights/1/bri', bridge.get_light(1, 'bri'))
    client.publish('mcctrl/lights/1/on', bridge.get_light(1, 'on'))
    client.publish('mcctrl/lights/2/bri', bridge.get_light(2, 'bri'))
    client.publish('mcctrl/lights/2/on', bridge.get_light(2, 'on'))
    client.publish('mcctrl/lights/3/bri', bridge.get_light(3, 'bri'))
    client.publish('mcctrl/lights/3/on', bridge.get_light(3, 'on'))
    time.sleep(10)

client.loop_stop()

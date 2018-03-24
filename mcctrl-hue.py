import time
import json
import random
import paho.mqtt.client as mqtt
from phue import Bridge

file = open('bridge.ip', 'r')
try:
    bridge_ip = file.read()
except:
    bridge_ip = '0.0.0.0'
finally:
    file.close()

file = open('mqtt.ip', 'r')
try:
    mqtt_ip = file.read()
except:
    mqtt_ip = '0.0.0.0'
finally:
    file.close()

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

    if (msg.topic == 'mcctrl/cmd/lights/1/bri'):
        bridge.set_light(1, 'bri', int(msg.payload))
    if (msg.topic == 'mcctrl/cmd/lights/2/bri'):
        bridge.set_light(2, 'bri', int(msg.payload))
    if (msg.topic == 'mcctrl/cmd/lights/3/bri'):
        bridge.set_light(3, 'bri', int(msg.payload))

    if (msg.topic == 'mcctrl/cmd/lights/1/on'):
        bridge.set_light(1, 'on', True if msg.payload == b'True' else False)
    if (msg.topic == 'mcctrl/cmd/lights/2/on'):
        bridge.set_light(2, 'on', True if msg.payload == b'True' else False)
    if (msg.topic == 'mcctrl/cmd/lights/3/on'):
        bridge.set_light(3, 'on', True if msg.payload == b'True' else False)

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
    time.sleep(2)
    client.publish('mcctrl/lights/on', bridge.get_group(1, 'on'))
    client.publish('mcctrl/lights/1/bri', bridge.get_light(1, 'bri'))
    client.publish('mcctrl/lights/1/on', bridge.get_light(1, 'on'))
    client.publish('mcctrl/lights/2/bri', bridge.get_light(2, 'bri'))
    client.publish('mcctrl/lights/2/on', bridge.get_light(2, 'on'))
    client.publish('mcctrl/lights/3/bri', bridge.get_light(3, 'bri'))
    client.publish('mcctrl/lights/3/on', bridge.get_light(3, 'on'))

client.loop_stop()

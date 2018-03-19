import time
import paho.mqtt.client as mqtt
from phue import Bridge

bridge = Bridge('192.168.1.28')
bridge.connect()


def on_connect(client, user_data, flags, rc):
    print("Connected with result code " + str(rc))
    client.subscribe('mcctrl/cmd/lights/on')
    client.subscribe('mcctrl/cmd/lights/+/bri')
    client.subscribe('mcctrl/cmd/lights/+/on')


def on_message(client, userdata, msg):
    print(msg.topic + " " + str(msg.payload))
    if (msg.topic == 'mcctrl/cmd/lights/on'):
        bridge.set_group(1, 'on', True if msg.payload == 'True' else False)

    if (msg.topic == 'mcctrl/cmd/lights/1/bri'):
        bridge.set_light(1, 'bri', int(msg.payload))
    if (msg.topic == 'mcctrl/cmd/lights/2/bri'):
        bridge.set_light(2, 'bri', int(msg.payload))
    if (msg.topic == 'mcctrl/cmd/lights/3/bri'):
        bridge.set_light(3, 'bri', int(msg.payload))

    if (msg.topic == 'mcctrl/cmd/lights/1/on'):
        bridge.set_light(1, 'on', True if msg.payload == 'True' else False)
    if (msg.topic == 'mcctrl/cmd/lights/2/on'):
        bridge.set_light(2, 'on', True if msg.payload == 'True' else False)
    if (msg.topic == 'mcctrl/cmd/lights/3/on'):
        bridge.set_light(3, 'on', True if msg.payload == 'True' else False)


client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
#client.connect('192.168.1.21')
client.connect('test.mosquitto.org')
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

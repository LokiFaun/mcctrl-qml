import time
import paho.mqtt.client as mqtt
from phue import Bridge

bridge = Bridge('192.168.1.28')
bridge.connect()
print bridge.get_group(1, 'on')


def on_connect(client, user_data, flags, rc):
    print("Connected with result code " + str(rc))
    client.subscribe("mcctrl/cmd/lights/on")


def on_message(client, userdata, msg):
    print(msg.topic + " " + str(msg.payload))
    if (msg.payload == 'True'):
        bridge.set_group(1, 'on', True)
    else:
        bridge.set_group(1, 'on', False)


client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect("192.168.1.21", 1883, 60)
client.loop_start()

while (True):
    time.sleep(2)
    client.publish("mcctrl/lights/on", bridge.get_group(1, 'on'))

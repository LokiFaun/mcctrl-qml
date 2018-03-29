#!/usr/bin/python3

import time
import random
import paho.mqtt.client as mqtt

file = open('mqtt.ip', 'r')
try:
    mqtt_ip = file.read()
except:
    mqtt_ip = '0.0.0.0'
finally:
    file.close()


def on_connect(client, user_data, flags, rc):
    print("Connected with result code " + str(rc))
    client.subscribe("mcctrl/temperature")


def on_message(client, userdata, msg):
    print(msg.topic + " " + str(msg.payload))


client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect(mqtt_ip, 1883, 60)
client.loop_start()

while True:
    time.sleep(2)
    degrees = random.randrange(15, 20)
    client.publish("mcctrl/temperature", '{0:0.3f}'.format(degrees))
    pressure = random.random() * 100
    client.publish("mcctrl/pressure", '{0:0.03f}'.format(pressure))

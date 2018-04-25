# mcctrl-qml

Man cave control using Qt5 QML

# Dependencies

## mcctrl

* [Qt5 v5.10.1](https://www.qt.io)
* [libmosquitto 1.4.15](https://github.com/eclipse/mosquitto)
* [mosquittopp 1.4.15](https://github.com/eclipse/mosquitto)
* [SQLite ORM v1.1](https://github.com/fnc12/sqlite_orm)
* [TagLib](https://github.com/taglib/taglib)

Qt5 needs to be installed on the development system.

SQLiteModernCpp, libmosquitto and mosquittopp are automatically downloaded as submodule.

## mqtt-hue, mqtt-temp

* [paho-mqtt](https://github.com/eclipse/paho.mqtt.python)
* [phue](https://github.com/studioimaginaire/phue)
* [Adafruit_BME280](https://github.com/adafruit/Adafruit_Python_BME280)

Install above package via pip/pip3.

# Build

* Clone repository
* Initialize submodules
* Install Qt5 5.10.1
* On Windows set Qt5 path in CMakeLists.txt
* On Raspberry Pi install mosquitto using prefered software package manager (apt,...)

For development and execution Qt5 needs to be cross-compiled.
Instructions can be found here: https://wiki.qt.io/RaspberryPi2EGLFS

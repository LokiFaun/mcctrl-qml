import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Controls.Universal 2.2
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4
import QtQuick.Dialogs 1.2
import QtCharts 2.2
import MqttClient 1.0
import SensorDb 1.0

ApplicationWindow {
    id: mcctrl
    visible: true

    height: 480
    width: 720

    flags: Qt.FramelessWindowHint | Qt.Window

    Universal.theme: Universal.Dark
    Universal.accent: Universal.Cyan
    Material.theme: Material.Dark
    Material.accent: Material.Blue

    Item {
        id: fontello
        readonly property string menu: "\uf0c9"
        readonly property string close: "\ue800"
        readonly property string home: "\ue801"
        readonly property string lightbulb: "\uf0eb"
        readonly property string desktop: "\uf108"
        readonly property string thermometer: "\uf2c8"
        readonly property string back: "\ue802"
    }


    property bool lightsOn: false
    property int light1_bri: 0
    property int light2_bri: 0
    property int light3_bri: 0
    property bool light1_on: false
    property bool light2_on: false
    property bool light3_on: false
    property double temperature: 0.0
    property double pressure: 0.0

    MqttClient {
        id: client
    }

    SensorDb {
        id: sensorDb
        connectionString: "test.sqlite"
    }

    function onLightsOnChanged(lightsOn) {
        console.log("Lights are: " + lightsOn ? "on!" : "off!");
        mcctrl.lightsOn = lightsOn;
    }

    function onLightBrightnessChanged(light, brightness) {
        console.log("light " + light + " has brightness: " + brightness)
        if (light === 1) {
            mcctrl.light1_bri = brightness;
        } else if (light === 2) {
            mcctrl.light2_bri = brightness;
        } else if (light === 3) {
            mcctrl.light3_bri = brightness;
        }
    }

    function onLightOnChanged(light, lightOn) {
        console.log("light " + light + " is " + lightOn ? "on" : "off");
        if (light === 1) {
            mcctrl.light1_on = lightOn;
        } else if (light === 2) {
            mcctrl.light2_on = lightOn;
        } else if (light === 3) {
            mcctrl.light3_on = lightOn;
        }
    }

    function onNewTemperatureReceived(value) {
        console.log("Adding temperature value: " + value);
        mcctrl.temperature = value;
        sensorDb.addTemperature(value);
    }

    function onNewPressureReceived(value) {
        console.log("Adding pressure value: " + value);
        mcctrl.pressure = value;
        sensorDb.addPressure(value);
    }

    Component.onCompleted: {
        client.onConnect.connect(function (isConnected) {
            if (isConnected) {
                console.log("MQTT connected");
            } else {
                console.log("MQTT disconnected");
            }
        });

        client.onLightsOnChanged.connect(onLightsOnChanged);
        client.onLightBrightnessChanged.connect(onLightBrightnessChanged);
        client.onLightOnChanged.connect(onLightOnChanged);
        client.onNewTemperature.connect(onNewTemperatureReceived);
        client.onNewPressure.connect(onNewPressureReceived);

        client.connect();
    }

    ColorDialog {
        id: colorDialog
        title: "Please choose a color"
        modality: "ApplicationModal"
        property int light: 0
        function rgb2xy(r, g, b) {
            r = (r > 0.04045) ? Math.pow((r + 0.055) / (1.0 + 0.055), 2.4) : (r / 12.92);
            g = (g > 0.04045) ? Math.pow((g + 0.055) / (1.0 + 0.055), 2.4) : (b / 12.92);
            b = (b > 0.04045) ? Math.pow((b + 0.055) / (1.0 + 0.055), 2.4) : (b / 12.92);
            var X = r * 0.664511 + g * 0.154324 + b * 0.162028;
            var Y = r * 0.283881 + g * 0.668433 + b * 0.047685;
            var Z = r * 0.000088 + g * 0.072310 + b * 0.986039;

            var x = X / (X + Y + Z);
            var y = Y / (X + Y + Z);
            return [x, y];
        }
        onAccepted: {
            if (light != 0) {
                var xy = rgb2xy(color.r, color.g, color.b);
                client.publish('mcctrl/cmd/lights/' + light + '/clr', '[' + xy + ']');
            }
        }
    }

    header: ToolBar {
        id: toolbar
        anchors.left: parent.left
        anchors.right: parent.right

        RowLayout {
            anchors.fill: parent
            ToolButton {
                id: toolbarMenuButton
                font.family: "mcctrl"
                font.pixelSize: 20
                text: fontello.menu

                onClicked: {
                    if (toolbarDrawer.opened) {
                        toolbarDrawer.close()
                    } else {
                        toolbarDrawer.open()
                    }
                }
            }
            Label {
                text: qsTr("McCtrl")
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
            ToolButton {
                id: closeButton
                anchors.right: parent.right
                font.family: "mcctrl"
                font.pixelSize: 30
                text: fontello.close
                onClicked: mcctrl.close()
            }
            ToolButton {
                id: homeButton
                anchors.right: closeButton.left
                font.family: "mcctrl"
                font.pixelSize: 20
                text: fontello.home
                onClicked: {
                    mainStack.clear()
                    mainStack.push(mainView)
                }
            }
            ToolButton {
                anchors.right: homeButton.left
                text: fontello.back
                onClicked: {
                    mainStack.pop()
                }
            }
        }
    }

    Drawer {
        id: toolbarDrawer
        y: header.height
        height: mcctrl.height - header.height
        edge: Qt.LeftEdge
        ColumnLayout {
            Button {
                id: hueMenuButton
                Layout.preferredWidth: 200
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                text: fontello.lightbulb + qsTr(" Hue")
                onClicked: {
                    mainStack.push(hue)
                    toolbarDrawer.close()
                }
            }
            Button {
                id: sensorMenuButton
                Layout.preferredWidth: 200
                anchors.top: hueMenuButton.bottom
                text: fontello.thermometer + qsTr(" Sensors")
                onClicked: {
                    mainStack.push(sensors)
                    toolbarDrawer.close()
                }
            }
            Button {
                id: systemMenuButton
                Layout.preferredWidth: 200
                anchors.top: sensorMenuButton.bottom
                text: fontello.desktop + qsTr(" System")
                onClicked: {
                    mainStack.push(system)
                    toolbarDrawer.close()
                }
            }
        }
    }

    StackView {
        id: mainStack
        initialItem: mainView

        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    Component {
        id: mainView
        GridLayout {
            columns: 4
            Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Material.elevation: 6
                Layout.column: 0
                Layout.columnSpan: 2
                text: fontello.lightbulb + qsTr(" Hue")
                font.pixelSize: 32
                onClicked: {
                    mainStack.push(hue)
                }
            }
            Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.column: 2
                Layout.columnSpan: 2
                Material.elevation: 6
                text: fontello.thermometer + qsTr(" Sensors")
                font.pixelSize: 32
                onClicked: {
                    mainStack.push(sensors)
                }
            }
            Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.row: 2
                Layout.column: 1
                Layout.columnSpan: 2
                Material.elevation: 6
                text: fontello.desktop + qsTr(" System")
                font.pixelSize: 32
                onClicked: {
                    mainStack.push(system)
                }
            }
        }
    }

    Component {
        id: hue
        RowLayout {
            Switch {
                text: "Room"
                checked: mcctrl.lightsOn
                onClicked: {
                    client.publish("mcctrl/cmd/lights/on", mcctrl.lightsOn === true ? "False" : "True")
                }
            }
            RowLayout {
                ColumnLayout {
                    Label {
                        text: "Light 1"
                    }
                    Switch {
                        checked: mcctrl.light1_on
                        onClicked: {
                            client.publish("mcctrl/cmd/lights/1/on", mcctrl.light1_on === true ? "False" : "True")
                        }
                    }
                    Slider {
                        from: 0
                        to: 254
                        stepSize: 1
                        value: mcctrl.light1_bri
                        orientation: "Vertical"
                        live: false
                        onValueChanged: {
                            client.publish("mcctrl/cmd/lights/1/bri", Math.round(value).toString())
                        }
                    }
                    RoundButton {
                        text: qsTr("C")
                        onClicked: {
                            colorDialog.light = 1;
                            colorDialog.visible = true
                        }
                    }
                }
                ColumnLayout {
                    Label {
                        text: "Light 2"
                    }
                    Switch {
                        checked: mcctrl.light2_on
                        onClicked: {
                            client.publish("mcctrl/cmd/lights/2/on", mcctrl.light2_on === true ? "False" : "True")
                        }
                    }
                    Slider {
                        from: 0
                        to: 254
                        stepSize: 1
                        value: mcctrl.light2_bri
                        orientation: "Vertical"
                        live: false
                        onValueChanged: {
                            client.publish("mcctrl/cmd/lights/2/bri", Math.round(value).toString())
                        }
                    }
                    RoundButton {
                        text: qsTr("C")
                        onClicked: {
                            colorDialog.light = 2;
                            colorDialog.visible = true
                        }
                    }
                }
                ColumnLayout {
                    Label {
                        text: "Light 3"
                    }
                    Switch {
                        checked: mcctrl.light3_on
                        onClicked: {
                            client.publish("mcctrl/cmd/lights/3/on", mcctrl.light3_on === true ? "False" : "True")
                        }
                    }
                    Slider {
                        from: 0
                        to: 254
                        stepSize: 1
                        value: mcctrl.light3_bri
                        orientation: "Vertical"
                        live: false
                        onValueChanged: {
                            client.publish("mcctrl/cmd/lights/3/bri", Math.round(value).toString())
                        }
                    }
                    RoundButton {
                        text: qsTr("C")
                        onClicked: {
                            colorDialog.light = 3;
                            colorDialog.visible = true
                        }
                    }
                }
            }
        }
    }

    Component {
        id: sensors
        GridLayout {
            columns: 2
            rows: 2
            ColumnLayout  {
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                Layout.column: 0
                Layout.row: 0
                Label {
                    Layout.alignment: Qt.AlignCenter
                    horizontalAlignment: "AlignHCenter"
                    text: qsTr("Temperature\n" + mcctrl.temperature + "°C")
                    font.pixelSize: 36
                }
            }
            ChartView {
                id: temperatureChart
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.column: 1
                Layout.row: 0
                theme: ChartView.ChartThemeDark
                Component.onCompleted: {
                    temperatureSeries.pointAdded.connect(function(index) {
                        console.log("Added temperature point at " + index);
                    });

                    sensorDb.updateTemperatureChart(temperatureSeries);
                    var count = temperatureSeries.count;
                    if (count > 0) {
                        temperatureDateAxis.min = new Date(temperatureSeries.at(count - 1).x);
                        temperatureDateAxis.max = new Date(temperatureSeries.at(0).x);
                        console.log("New min date: " + temperatureDateAxis.min);
                        console.log("New max date: " + temperatureDateAxis.max);
                    }

                    temperatureChart.update()
                }

                LineSeries {
                    id: temperatureSeries
                    name: qsTr("Temperature")
                    color: "red"
                    axisX: DateTimeAxis {
                        id: temperatureDateAxis
                        format: "hh:mm"
                    }
                    axisY: ValueAxis {
                        min: -20
                        max: 40
                    }
                }
            }
            ColumnLayout {
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                Layout.column: 0
                Layout.row: 1
                Label {
                    Layout.alignment: Qt.AlignCenter
                    horizontalAlignment: "AlignHCenter"
                    text: qsTr("Pressure\n" + mcctrl.pressure + "hPa")
                    font.pixelSize: 36
                }
            }
            ChartView {
                id: pressureChart
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.column: 1
                Layout.row: 1
                theme: ChartView.ChartThemeDark
                Component.onCompleted: {
                    pressureSeries.pointAdded.connect(function(index) {
                        console.log("Added pressure point at " + index);
                    });

                    sensorDb.updatePressureChart(pressureSeries);
                    var count = pressureSeries.count;
                    if (count > 0) {
                        pressureDateAxis.min = new Date(pressureSeries.at(count - 1).x);
                        pressureDateAxis.max = new Date(pressureSeries.at(0).x);
                        console.log("New min date: " + pressureDateAxis.min);
                        console.log("New max date: " + pressureDateAxis.max);
                    }

                    temperatureChart.update()
                }

                LineSeries {
                    id: pressureSeries
                    name: qsTr("Pressure")
                    color: "green"
                    axisX: DateTimeAxis {
                        id: pressureDateAxis
                        format: "hh:mm"
                    }
                    axisY: ValueAxis {
                        min: 800
                        max: 1100
                    }
                }
            }
        }
    }

    Component {
        id: system
        Label {
            text: "system"
        }
    }
}

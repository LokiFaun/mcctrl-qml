import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Controls.Universal 2.2
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4
import QtQuick.Dialogs 1.2
import MqttClient 1.0

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
        readonly property string menu: qsTr("\uf0c9")
        readonly property string close: qsTr("\ue800")
        readonly property string home: qsTr("\ue801")
        readonly property string lightbulb: qsTr("\uf0eb")
        readonly property string desktop: qsTr("\uf108")
        readonly property string thermometer: qsTr("\uf2c8")
    }

    property bool lightsOn: false
    property int light1_bri: 0
    property int light2_bri: 0
    property int light3_bri: 0
    property bool light1_on: false
    property bool light2_on: false
    property bool light3_on: false

    MqttClient {
        id: client
    }

    function onMqttConnected(isConnected) {
        console.log("MQTT connected");
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

    Component.onCompleted: {
        client.connect()
        client.onConnect.connect(onMqttConnected)
        client.onLightsOnChanged.connect(onLightsOnChanged)
        client.onLightBrightnessChanged.connect(onLightBrightnessChanged)
        client.onLightOnChanged.connect(onLightOnChanged)
    }

    ColorDialog {
        id: colorDialog
        title: "Please choose a color"
        modality: "ApplicationModal"
        property int light: 0
        onAccepted: {
            if (light != 0) {
                console.log("Setting light " + light);
                console.log("Red: " + color.r);
                console.log("Green: " + color.g);
                console.log("Blue: " + color.b);
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

                property bool toolbarActive: false
                function closeToolbar() {
                    if (!toolbarMenuButton.toolbarActive) {
                        return
                    }

                    mainStack.pop()
                    toolbarMenuButton.toolbarActive = false
                }

                onClicked: {
                    if (!toolbarActive) {
                        mainStack.push(toolbarMenu)
                        toolbarMenuButton.toolbarActive = true
                    } else {
                        toolbarMenuButton.closeToolbar()
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
                anchors.right: closeButton.left
                font.family: "mcctrl"
                font.pixelSize: 20
                text: fontello.home
                onClicked: {
                    toolbarMenuButton.closeToolbar()
                    mainStack.push(mainView)
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
        id: toolbarMenu
        RowLayout {
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                GridLayout {
                    columns: 1
                    anchors.fill: parent
                    Button {
                        text: qsTr("Hue")
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        onClicked: {
                            toolbarMenuButton.closeToolbar()
                            mainStack.push(hue)
                        }
                    }
                    Button {
                        text: qsTr("Sensors")
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                    Button {
                        text: qsTr("System")
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        onClicked: {
                            toolbarMenuButton.closeToolbar()
                            mainStack.push(system)
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Item {
                Layout.fillWidth: true
            }
        }
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
                text: qsTr("Hue")
                onClicked: {
                    toolbarMenuButton.closeToolbar()
                    mainStack.push(hue)
                }
            }
            Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.column: 2
                Layout.columnSpan: 2
                Material.elevation: 6
                text: qsTr("Sensors")
            }
            Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.row: 2
                Layout.column: 1
                Layout.columnSpan: 2
                Material.elevation: 6
                text: qsTr("System")
                onClicked: {
                    toolbarMenuButton.closeToolbar()
                    mainStack.push(system)
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
                            client.publish("mcctrl/cmd/lights/1/on", mcctrl.light2_on === true ? "False" : "True")
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
}

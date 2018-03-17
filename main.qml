import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Controls.Universal 2.2
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4
import MqttClient 1.0

ApplicationWindow {
    id: applicationWindow
    visible: true

    height: 480
    width: 720

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

    MqttClient {
        id: client
    }

    function onMessage(topic, payload) {
        console.log("RECEIVED: " + topic);
        console.log("PAYLOAD" + payload);
        if (topic === 'mcctrl/lights/on') {
            console.log("Setting hueState");
            hueButton.hueState = payload === 'True';
        }
    }

    function onMqttConnected(isConnected) {
        console.log("MQTT connected");
    }

    Component.onCompleted: {
        client.connect()
        client.onMessage.connect(onMessage)
        client.onConnect.connect(onMqttConnected)
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
                onClicked: applicationWindow.close()
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
                id: hueButton
                property bool hueState: false
                Component.onCompleted: {
                    console.log("Subscribe to hue-lights");
                    client.subscribe("mcctrl/lights/on");
                }

                onClicked: {
                    if (hueButton.hueState === true) {
                        client.publish("mcctrl/cmd/lights/on", "False")
                        hueButton.hueState = false;
                    } else {
                        client.publish("mcctrl/cmd/lights/on", "True")
                        hueButton.hueState = true;
                    }
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
}

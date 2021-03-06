import QtQuick 2.10
import QtQuick.Controls 1.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Controls.Universal 2.2
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4
import QtQuick.Dialogs 1.2
import QtCharts 2.2
import QtMultimedia 5.9
import Qt.labs.platform 1.0
import Qt.labs.folderlistmodel 2.2
import mcctrl 1.0

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
        readonly property string close: "\ue800"
        readonly property string home: "\ue801"
        readonly property string back: "\ue802"
        readonly property string headphones: "\ue803"
        readonly property string play: "\ue804"
        readonly property string stop: "\ue805"
        readonly property string pause: "\ue806"
        readonly property string next: "\ue807"
        readonly property string previous: "\ue808"
        readonly property string lightbulb: "\uf0eb"
        readonly property string menu: "\uf0c9"
        readonly property string desktop: "\uf108"
        readonly property string thermometer: "\uf2c8"
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

    SensorDb {
        id: sensorDb
        connectionString: "test.sqlite"
    }

    Audio {
        id: musicPlayer
        property string folder: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
        playlist: Playlist {
            id: musicList
        }
        onStatusChanged: {
            if (status == Audio.EndOfMedia) {
                musicList.next()
            }
        }
    }

    function onLightsOnChanged(lightsOn) {
        console.log("Lights are: " + lightsOn ? "on!" : "off!")
        mcctrl.lightsOn = lightsOn
    }

    function onLightBrightnessChanged(light, brightness) {
        console.log("light " + light + " has brightness: " + brightness)
        if (light === 1) {
            mcctrl.light1_bri = brightness
        } else if (light === 2) {
            mcctrl.light2_bri = brightness
        } else if (light === 3) {
            mcctrl.light3_bri = brightness
        }
    }

    function onLightOnChanged(light, lightOn) {
        console.log("light " + light + " is " + lightOn ? "on" : "off")
        if (light === 1) {
            mcctrl.light1_on = lightOn
        } else if (light === 2) {
            mcctrl.light2_on = lightOn
        } else if (light === 3) {
            mcctrl.light3_on = lightOn
        }
    }

    function onNewTemperatureReceived(value) {
        console.log("Adding temperature value: " + value)
        mcctrl.temperature = value
        sensorDb.addTemperature(value)
    }

    function onNewPressureReceived(value) {
        console.log("Adding pressure value: " + value)
        mcctrl.pressure = value
        sensorDb.addPressure(value)
    }

    Component.onCompleted: {
        client.onConnect.connect(function (isConnected) {
            if (isConnected) {
                console.log("MQTT connected")
            } else {
                console.log("MQTT disconnected")
            }
        })

        client.onLightsOnChanged.connect(onLightsOnChanged)
        client.onLightBrightnessChanged.connect(onLightBrightnessChanged)
        client.onLightOnChanged.connect(onLightOnChanged)
        client.onNewTemperature.connect(onNewTemperatureReceived)
        client.onNewPressure.connect(onNewPressureReceived)

        client.connect()
    }

    ColorDialog {
        id: colorDialog
        title: "Please choose a color"
        modality: "ApplicationModal"
        property int light: 0
        function rgb2xy(r, g, b) {
            r = (r > 0.04045) ? Math.pow((r + 0.055) / (1.0 + 0.055), 2.4) : (r / 12.92)
            g = (g > 0.04045) ? Math.pow((g + 0.055) / (1.0 + 0.055), 2.4) : (b / 12.92)
            b = (b > 0.04045) ? Math.pow((b + 0.055) / (1.0 + 0.055), 2.4) : (b / 12.92)
            var X = r * 0.664511 + g * 0.154324 + b * 0.162028
            var Y = r * 0.283881 + g * 0.668433 + b * 0.047685
            var Z = r * 0.000088 + g * 0.072310 + b * 0.986039

            var x = X / (X + Y + Z)
            var y = Y / (X + Y + Z)
            return [x, y]
        }
        onAccepted: {
            if (light != 0) {
                var xy = rgb2xy(color.r, color.g, color.b)
                client.publish('mcctrl/cmd/lights/' + light + '/clr', '[' + xy + ']')
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
                text: if (musicPlayer.playbackState === Audio.PlayingState) {
                          qsTr("McCtrl - ") + musicPlayer.metaData.albumArtist + ": " + musicPlayer.metaData.title
                      } else {
                          qsTr("McCtrl")
                      }

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
                id: mediaMenuButton
                Layout.preferredWidth: 200
                anchors.top: sensorMenuButton.bottom
                text: fontello.headphones + qsTr(" Media")
                onClicked: {
                    mainStack.push(mediaPlayer)
                    toolbarDrawer.close()
                }
            }
            Button {
                id: systemMenuButton
                Layout.preferredWidth: 200
                anchors.top: mediaMenuButton.bottom
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
                            colorDialog.light = 1
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
                            colorDialog.light = 2
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
                            colorDialog.light = 3
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
                    id: currentTemperature
                    Layout.alignment: Qt.AlignCenter
                    horizontalAlignment: "AlignHCenter"
                    property double value: 0.0
                    text: qsTr("Temperature\n" + currentTemperature.value + "°C")
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
                antialiasing: true

                Timer {
                    interval: 600000 // 10min
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        currentTemperature.value = sensorDb.getLastTemperatureValue()
                        sensorDb.updateTemperatureChart(temperatureSeries, temperatureDateAxis, temperatureValueAxis)
                        temperatureChart.update()
                    }
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
                        id: temperatureValueAxis
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
                    id: currentPressure
                    Layout.alignment: Qt.AlignCenter
                    horizontalAlignment: "AlignHCenter"
                    property double value: 0.0
                    text: qsTr("Pressure\n" + currentPressure.value + "hPa")
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
                antialiasing: true

                Timer {
                    interval: 600000 // 10min
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        currentPressure.value = sensorDb.getLastPressureValue()
                        sensorDb.updatePressureChart(pressureSeries, pressureDateAxis, pressureValueAxis)
                        pressureChart.update()
                    }
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
                        id: pressureValueAxis
                        min: 800
                        max: 1100
                    }
                }
            }
        }
    }

    Component {
        id: mediaPlayer
        GridLayout {
            rows: 2
            columns: 3
            ListView {
                id: folderView
                Layout.row: 0
                Layout.column: 0
                Layout.fillHeight: true
                Layout.fillWidth: true
                model: FolderListModel {
                    id: musicFolders
                    showDirs: true
                    showDotAndDotDot: true
                    showOnlyReadable: true
                    showHidden: false
                    showFiles: false
                    folder: musicPlayer.folder
                    rootFolder: musicPlayer.folder
                }
                delegate: Button {
                    width: folderView.width
                    text: fileName
                    onClicked: {
                        musicFiles.folder = fileURL
                        musicFolders.folder = fileURL
                    }
                }
            }
            ListView {
                Layout.row: 0
                Layout.column: 1
                Layout.fillHeight: true
                Layout.fillWidth: true
                model: FolderListModel {
                    id: musicFiles
                    nameFilters: ["*.mp3"]
                    showDirs: false
                    showDotAndDotDot: false
                    showOnlyReadable: true
                    showHidden: false
                    showFiles: true
                    rootFolder: musicPlayer.folder
                }
                delegate: Button {
                    width: folderView.width
                    text: fileName
                    onClicked: {
                        musicList.addItem(fileURL)
                        if (musicPlayer.playbackState !== Audio.PlayingState) {
                            musicPlayer.play()
                        }
                    }
                }
            }
            ListView {
                id: musicListView
                Layout.row: 0
                Layout.column: 2
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 1
                model: musicList
                header: Text { text: "Playlist" }
                delegate: Pane {
                    width: musicListView.width
                    Material.elevation: 3
                    contentHeight: 18
                    Text {
                        anchors.fill: parent
                        text: AudioFormatter.format(source, "%artist - %title")
                    }
                }
            }
            Button {
                Layout.row: 1
                Layout.column: 0
                Layout.fillWidth: true
                height: 18
                text: fontello.previous
                onClicked: musicPlayer.playlist.previous()
            }
            Button {
                Layout.row: 1
                Layout.column: 1
                Layout.fillWidth: true
                height: 18
                text: {
                    if (musicPlayer.playbackState === Audio.PlayingState) {
                        return fontello.pause
                    } else {
                        return fontello.play
                    }
                }
                onClicked: {
                    if (musicPlayer.playbackState !== Audio.PlayingState) {
                        musicPlayer.play()
                    } else {
                        musicPlayer.pause()
                    }
                }
            }
            Button {
                Layout.row: 1
                Layout.column: 2
                Layout.fillWidth: true
                height: 18
                text: fontello.next
                onClicked: musicPlayer.playlist.next()
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

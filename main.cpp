#include "qmlmqttclient.h"

#include <QApplication>
#include <QDebug>
#include <QDirModel>
#include <QFileSystemModel>
#include <QFontDatabase>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>

#include "audioformatter.h"
#include "mosquittopp.h"
#include "sensordb.h"

int main(int argc, char* argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);

    mosqpp::lib_init();

    if (QFontDatabase::addApplicationFont(":/fontello/font/mcctrl.ttf") == -1) {
        qWarning() << "Could not load font";
    }

    qmlRegisterType<QmlMqttClient>("mcctrl", 1, 0, "MqttClient");
    qmlRegisterType<SensorDb>("mcctrl", 1, 0, "SensorDb");
    qmlRegisterSingletonType<AudioFormatter>("mcctrl", 1, 0, "AudioFormatter", [](QQmlEngine*, QJSEngine*) -> QObject* {return new AudioFormatter(); });

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    int rc = -1;
    if (!engine.rootObjects().isEmpty()) {
        rc = QApplication::exec();
    }

    mosqpp::lib_cleanup();
    return rc;
}
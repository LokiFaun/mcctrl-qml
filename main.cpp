#include "qmlmqttclient.h"

#include <QDebug>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <mosquittopp.h>

int main(int argc, char* argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    mosqpp::lib_init();

    if (QFontDatabase::addApplicationFont(":/fontello/font/mcctrl.ttf") == -1) {
        qWarning() << "Could not load font";
    }

    qmlRegisterType<QmlMqttClient>("MqttClient", 1, 0, "MqttClient");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    int rc = -1;
    if (!engine.rootObjects().isEmpty()) {
        rc = app.exec();
    }

    mosqpp::lib_cleanup();
    return rc;
}

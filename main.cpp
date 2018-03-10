#include "qmlmqttclient.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <mosquittopp.h>

int main(int argc, char* argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    mosqpp::lib_init();

    QQuickStyle::setStyle("Material");

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
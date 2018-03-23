#include "qmlmqttclient.h"

#include "mqtt.ip.h"
#include <QDebug>
#include <QMutexLocker>
#include <QString>
#include <mosquittopp.h>

QmlMqttClient::QmlMqttClient(QObject* parent)
    : QThread(parent)
    , m_IsConnected(false)
    , m_Host(mqtt_ip)
    , m_Port(1883)
{
    QThread::start();
}

QmlMqttClient::~QmlMqttClient()
{
    shutdown();
    mosqpp::mosquittopp::disconnect();
    QThread::wait();
}

void QmlMqttClient::connect()
{
    mosqpp::mosquittopp::connect(m_Host.toStdString().c_str(), m_Port);
}

void QmlMqttClient::subscribe(const QString& topic)
{
    std::string const tp = topic.toStdString();
    mosqpp::mosquittopp::subscribe(nullptr, tp.c_str());
}

void QmlMqttClient::publish(const QString& topic, const QString& payload)
{
    static const int qos = 1;
    qDebug() << "Publishing: " << topic << " - " << payload;
    MqttMessage msg;
    msg.topic = topic;
    msg.payload = payload;
    m_PublishQueue.enqueue(msg);
}

int QmlMqttClient::port() const
{
    QMutexLocker lock(&m_CS);
    return m_Port;
}

void QmlMqttClient::setPort(int const port)
{
    QMutexLocker lock(&m_CS);
    if (m_Port != port) {
        if (isConnected()) {
            mosqpp::mosquittopp::disconnect();
        }

        mosqpp::mosquittopp::connect(m_Host.toStdString().c_str(), m_Port);
    }

    m_Port = port;
    emit portChanged(m_Port);
}

QString QmlMqttClient::host() const
{
    QMutexLocker lock(&m_CS);
    return m_Host;
}

void QmlMqttClient::setHost(const QString& host)
{
    QMutexLocker lock(&m_CS);
    if (m_Host != host) {
        if (isConnected()) {
            mosqpp::mosquittopp::disconnect();
        }

        mosqpp::mosquittopp::connect(m_Host.toStdString().c_str(), m_Port);
    }

    m_Host = host;
    emit hostChanged(m_Host);
}

bool QmlMqttClient::isConnected() const
{
    QMutexLocker lock(&m_CS);
    return m_IsConnected;
}

void QmlMqttClient::setIsConnected(bool const isConnected)
{
    QMutexLocker lock(&m_CS);
    m_IsConnected = isConnected;
    emit onConnect(m_IsConnected);
}

void QmlMqttClient::on_connect(int const rc)
{
    if (rc == 0) {
        setIsConnected(true);
        subscribe("mcctrl/lights/on");
        subscribe("mcctrl/lights/+/bri");
        subscribe("mcctrl/lights/+/on");
    }
}
void QmlMqttClient::on_disconnect(int rc)
{
    if (rc == 0) {
        setIsConnected(false);
    }
}
void QmlMqttClient::on_message(const struct mosquitto_message* message)
{
    const QString msg = QString::fromLocal8Bit(static_cast<const char*>(message->payload), message->payloadlen);
    const QString topic = QString::fromLocal8Bit(message->topic);

    qDebug() << "Received TOPIC: " << topic;
    qDebug() << "Received PAYLOAD: " << msg;

    if (topic == "mcctrl/lights/on") {
        emit onLightsOnChanged(msg == "True");
    } else if (topic == "mcctrl/lights/1/bri") {
        emit onLightBrightnessChanged(1, msg.toInt());
    } else if (topic == "mcctrl/lights/2/bri") {
        emit onLightBrightnessChanged(2, msg.toInt());
    } else if (topic == "mcctrl/lights/3/bri") {
        emit onLightBrightnessChanged(3, msg.toInt());
    } else if (topic == "mcctrl/lights/1/on") {
        emit onLightOnChanged(1, msg == "True");
    } else if (topic == "mcctrl/lights/2/on") {
        emit onLightOnChanged(2, msg == "True");
    } else if (topic == "mcctrl/lights/3/on") {
        emit onLightOnChanged(3, msg == "True");
    }
}

void QmlMqttClient::on_log(int const, const char* const)
{
}

void QmlMqttClient::on_error()
{
    qDebug() << "error";
}

void QmlMqttClient::shutdown()
{
    QMutexLocker lock(&m_CS);
    m_ShutdownCondition.wakeAll();
}

bool QmlMqttClient::isShutdown()
{
    QMutexLocker lock(&m_CS);
    return m_ShutdownCondition.wait(&m_CS, 100);
}

void QmlMqttClient::run()
{
    static const int qos = 1;
    int rc = 0;
    while (!isShutdown()) {
        rc = mosqpp::mosquittopp::loop(100);
        if (rc) {
            mosqpp::mosquittopp::reconnect();
        } else if (!m_PublishQueue.isEmpty()) {
            MqttMessage const msg = m_PublishQueue.dequeue();
            std::string const topic = msg.topic.toStdString();
            std::string const payload = msg.payload.toStdString();
            mosqpp::mosquittopp::publish(nullptr,
                topic.c_str(),
                msg.payload.length(),
                payload.c_str(),
                qos);
        }
    }
}

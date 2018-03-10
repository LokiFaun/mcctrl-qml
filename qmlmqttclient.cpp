#include "qmlmqttclient.h"

#include <QDebug>
#include <QMutexLocker>
#include <QString>
#include <mosquittopp.h>

QmlMqttClient::QmlMqttClient(QObject* parent)
    : QThread(parent)
    , m_IsConnected(false)
    , m_Host("192.168.1.21")
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

void QmlMqttClient::connectToHost()
{
    mosqpp::mosquittopp::connect(m_Host.toStdString().c_str(), m_Port);
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

        mosqpp::mosquittopp::connect("test.mosquitto.org", m_Port);
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
        mosqpp::mosquittopp::subscribe(nullptr, "mcctrl/temperature");
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

    emit onMessage(topic, msg);
}

void QmlMqttClient::on_log(int const level, const char* const str)
{
    qDebug() << "Log[" << level << "]: " << str;
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
    int rc = 0;
    while (!isShutdown()) {
        rc = mosqpp::mosquittopp::loop();
        if (rc) {
            mosqpp::mosquittopp::reconnect();
        }
    }
}

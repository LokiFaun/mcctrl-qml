#ifndef QMLMQTTCLIENT_H
#define QMLMQTTCLIENT_H

#include <QMutex>
#include <QObject>
#include <QString>
#include <QThread>
#include <QWaitCondition>
#include <mosquittopp.h>

class QmlMqttClient
    : public QThread,
      public mosqpp::mosquittopp {
    Q_OBJECT
    Q_PROPERTY(bool isConnected MEMBER m_IsConnected NOTIFY onConnect)
    Q_PROPERTY(QString host MEMBER m_Host NOTIFY hostChanged)
    Q_PROPERTY(int port MEMBER m_Port NOTIFY portChanged)
public:
    explicit QmlMqttClient(QObject* parent = nullptr);
    virtual ~QmlMqttClient();

    Q_INVOKABLE void connect();
    Q_INVOKABLE void subscribe(QString const& topic);
    Q_INVOKABLE void publish(QString const& topic, QString const& msg);

    bool isConnected() const;
    void setIsConnected(bool isConnected);

    QString host() const;
    void setHost(const QString& host);

    int port() const;
    void setPort(int port);

    // mosquittopp interface
    virtual void on_connect(int rc) override;
    virtual void on_disconnect(int rc) override;
    virtual void on_message(const struct mosquitto_message* message) override;
    virtual void on_log(int level, const char* str) override;
    virtual void on_error() override;

    virtual void run() override;

Q_SIGNALS:
    void onMessage(const QString&, const QString&);
    void onConnect(bool);
    void hostChanged(const QString&);
    void portChanged(int);

private:
    void shutdown();
    bool isShutdown();

    mutable QMutex m_CS;
    QWaitCondition m_ShutdownCondition;
    bool m_IsConnected;
    QString m_Host;
    int m_Port;
};

#endif // QMLMQTTCLIENT_H

#ifndef SENSORDB_H
#define SENSORDB_H

#include <QObject>
#include <QString>

struct Temperature {
    int id;
    std::string time;
    double value;
};

struct Pressure {
    int id;
    std::string time;
    double value;
};

class SensorDb : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString connectionString MEMBER m_ConnectionString NOTIFY connectionStringChanged)
public:
    explicit SensorDb(QObject* parent = nullptr);

    Q_INVOKABLE void load();

    QString connectionString() const;
    void setConnectionString(const QString& connectionString);

    Q_INVOKABLE void addTemperature(QString const& time, double value);
    Q_INVOKABLE void addPressure(QString const& time, double value);

Q_SIGNALS:
    void connectionStringChanged(QString const&);
    void onLoadTemperature(QVector<Temperature> const& values);
    void onLoadPressure(QVector<Pressure> const& values);
    void onNewTemperature(Temperature const& value);
    void onNewPressure(Pressure const& value);

private:
    QString m_ConnectionString;
};

#endif // SENSORDB_H

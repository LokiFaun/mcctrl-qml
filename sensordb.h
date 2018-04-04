#ifndef SENSORDB_H
#define SENSORDB_H

#include <QObject>
#include <QString>
#include <QVariantList>

namespace QtCharts {
class QAbstractSeries;
}

struct Temperature {
    qint32 id;
    qint64 time;
    double value;
};

struct Pressure {
    qint32 id;
    qint64 time;
    double value;
};

class SensorDb : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString connectionString MEMBER m_ConnectionString NOTIFY connectionStringChanged)
public:
    explicit SensorDb(QObject* parent = nullptr);

    QString connectionString() const;
    void setConnectionString(const QString& connectionString);

    Q_INVOKABLE void addTemperature(double value);
    Q_INVOKABLE void addPressure(double value);

    Q_INVOKABLE QVariantList getTemperatureValues() const;

    Q_INVOKABLE void updateTemperatureChart(QtCharts::QAbstractSeries* pSeries);
    Q_INVOKABLE void updatePressureChart(QtCharts::QAbstractSeries* pSeries);

Q_SIGNALS:
    void connectionStringChanged(QString const&);

private:
    template <typename T>
    void updateChart(QtCharts::QAbstractSeries* pSeries, std::string const& tableName);

    QString m_ConnectionString;
};

#endif // SENSORDB_H

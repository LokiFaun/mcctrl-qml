#include "sensordb.h"
#include <QAbstractSeries>
#include <QDateTime>
#include <QDebug>
#include <QLineSeries>
#include <QVector>

#include <sqlite_orm/sqlite_orm.h>

static std::string const TemperatureTable = "Temperature";
static std::string const PressureTable = "Pressure";

auto initStorage(QString const& connectionString)
{
    auto storage = sqlite_orm::make_storage(connectionString.toStdString(),
        sqlite_orm::make_table(TemperatureTable,
            sqlite_orm::make_column("id",
                &Temperature::id,
                sqlite_orm::autoincrement(),
                sqlite_orm::primary_key()),
            sqlite_orm::make_column("time",
                &Temperature::time),
            sqlite_orm::make_column("value",
                &Temperature::value)),
        sqlite_orm::make_table(PressureTable,
            sqlite_orm::make_column("id",
                &Pressure::id,
                sqlite_orm::autoincrement(),
                sqlite_orm::primary_key()),
            sqlite_orm::make_column("time",
                &Pressure::time),
            sqlite_orm::make_column("value",
                &Pressure::value)));
    storage.sync_schema();
    return storage;
}

SensorDb::SensorDb(QObject* parent)
    : QObject(parent)
    , m_ConnectionString(":memory:")
{
}

QString SensorDb::connectionString() const
{
    return m_ConnectionString;
}

void SensorDb::setConnectionString(const QString& connectionString)
{
    m_ConnectionString = connectionString;
    emit connectionStringChanged(m_ConnectionString);
}

void SensorDb::addTemperature(double value)
{
    qDebug() << "Adding temperature value: " << value;
    auto storage = initStorage(m_ConnectionString);
    if (!storage.table_exists(TemperatureTable)) {
        qWarning() << TemperatureTable.c_str() << " does not exist";
        return;
    }

    QDateTime const now = QDateTime::currentDateTimeUtc();
    auto id = storage.insert(Temperature{ 0, now.toMSecsSinceEpoch(), value });
    auto inserted = storage.get_no_throw<Temperature>(id);
    if (inserted) {
        qDebug() << "Inserted new temperature(" << value << ", " << now.toString() << ") with id " << id;
    }
}

void SensorDb::addPressure(double value)
{
    qDebug() << "Adding pressure value: " << value;
    auto storage = initStorage(m_ConnectionString);
    if (!storage.table_exists(PressureTable)) {
        qWarning() << PressureTable.c_str() << " does not exist";
        return;
    }

    QDateTime const now = QDateTime::currentDateTimeUtc();
    auto id = storage.insert(Pressure{ 0, now.toMSecsSinceEpoch(), value });
    auto inserted = storage.get_no_throw<Pressure>(id);
    if (inserted) {
        qDebug() << "Inserted new pressure(" << value << ", " << now.toString() << ") with id " << id;
    }
}

QVariantList SensorDb::getTemperatureValues() const
{
    QVariantList temperaturePoints;
    auto storage = initStorage(m_ConnectionString);
    if (!storage.table_exists(TemperatureTable)) {
        return temperaturePoints;
    }

    qDebug() << "Loading " << TemperatureTable.c_str() << " values";
    auto values = storage.get_all<Temperature>(
        sqlite_orm::order_by(&Temperature::id).desc(),
        sqlite_orm::limit(10));
    for (auto const& value : values) {
        temperaturePoints.push_back(QPointF(value.time, value.value));
    }

    return temperaturePoints;
}

void SensorDb::updateTemperatureChart(QtCharts::QAbstractSeries* pSeries)
{
    updateChart<Temperature>(pSeries, TemperatureTable);
}

void SensorDb::updatePressureChart(QtCharts::QAbstractSeries* pSeries)
{
    updateChart<Pressure>(pSeries, PressureTable);
}

template <typename T>
void SensorDb::updateChart(QtCharts::QAbstractSeries* pSeries, const std::string& tableName)
{
    if (!pSeries) {
        return;
    }

    auto storage = initStorage(m_ConnectionString);
    if (!storage.table_exists(tableName)) {
        return;
    }

    qDebug() << "Loading " << tableName.c_str() << " values";
    auto values = storage.get_all<T>(sqlite_orm::order_by(&T::id).desc(), sqlite_orm::limit(10));
    QList<QPointF> temperaturePoints;
    for (auto const& value : values) {
        temperaturePoints.push_back(QPointF(value.time, value.value));
    }

    auto* pLineSeries = dynamic_cast<QtCharts::QLineSeries*>(pSeries);
    if (pLineSeries) {
        if (pLineSeries->points().empty()) {
            pLineSeries->append(temperaturePoints);
        } else {
            pLineSeries->replace(temperaturePoints);
        }
    }
}

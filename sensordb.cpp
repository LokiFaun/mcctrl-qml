#include "sensordb.h"
#include <QAbstractSeries>
#include <QDateTime>
#include <QDateTimeAxis>
#include <QDebug>
#include <QLineSeries>
#include <QValueAxis>
#include <QVector>

static std::string const TemperatureTable = "Temperature";
static std::string const PressureTable = "Pressure";

#if _MSC_VER
// disable warnings for sqlite_orm
#pragma warning(push, 0)
#endif

#include <sqlite_orm/sqlite_orm.h>

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

#if _MSC_VER
#pragma warning(pop)
#endif

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

double SensorDb::getLastTemperatureValue() const
{
    QVariant value = getLastValue<Temperature>(TemperatureTable);
    if (value.isValid()) {
        return value.value<Temperature>().value;
    }

    return 0.0;
}

double SensorDb::getLastPressureValue() const
{
    QVariant value = getLastValue<Pressure>(PressureTable);
    if (value.isValid()) {
        return value.value<Pressure>().value;
    }

    return 0.0;
}

void SensorDb::updateTemperatureChart(QtCharts::QAbstractSeries* pSeries, QtCharts::QAbstractAxis* pXAxis, QtCharts::QAbstractAxis* pYAxis)
{
    updateChart<Temperature>(pSeries, pXAxis, pYAxis, TemperatureTable);
}

void SensorDb::updatePressureChart(QtCharts::QAbstractSeries* pSeries, QtCharts::QAbstractAxis* pXAxis, QtCharts::QAbstractAxis* pYAxis)
{
    updateChart<Pressure>(pSeries, pXAxis, pYAxis, PressureTable);
}

template <typename T>
void SensorDb::updateChart(QtCharts::QAbstractSeries* pSeries, QtCharts::QAbstractAxis* pXAxis, QtCharts::QAbstractAxis* pYAxis, const std::string& tableName) const
{
    if (!pSeries || !pXAxis || !pYAxis) {
        return;
    }

    auto storage = initStorage(m_ConnectionString);
    if (!storage.table_exists(tableName)) {
        return;
    }

    qDebug() << "Loading " << tableName.c_str() << " values";
    auto values = storage.get_all<T, QVector<T>>();
    if (values.count() > 10) {
        values = values.mid(values.count() - 10);
    }

    QList<QPointF> points;
    qint64 minDate = std::numeric_limits<qint64>::max();
    qint64 maxDate = std::numeric_limits<qint64>::min();
    double minValue = std::numeric_limits<double>::max();
    double maxValue = std::numeric_limits<double>::min();

    for (auto const& value : values) {
        points.push_back(QPointF(value.time, value.value));
        minDate = std::min(minDate, value.time);
        maxDate = std::max(maxDate, value.time);
        minValue = std::min(minValue, value.value);
        maxValue = std::max(maxValue, value.value);
    }

    auto pLineSeries = dynamic_cast<QtCharts::QLineSeries*>(pSeries);
    if (pLineSeries) {
        if (pLineSeries->points().empty()) {
            pLineSeries->append(points);
        } else {
            pLineSeries->replace(points);
        }
    }

    auto pDateAxis = dynamic_cast<QtCharts::QDateTimeAxis*>(pXAxis);
    if (pDateAxis) {
        pDateAxis->setMin(QDateTime::fromMSecsSinceEpoch(minDate));
        pDateAxis->setMax(QDateTime::fromMSecsSinceEpoch(maxDate));
    }

    auto pValueAxis = dynamic_cast<QtCharts::QValueAxis*>(pYAxis);
    if (pValueAxis) {
        pValueAxis->setMin(minValue);
        pValueAxis->setMax(maxValue);
    }
}

template <typename T>
QVariant SensorDb::getLastValue(std::string const& tableName) const
{
    auto storage = initStorage(m_ConnectionString);
    if (!storage.table_exists(tableName)) {
        return QVariant();
    }

    qDebug() << "Loading latest " << tableName.c_str() << " value";
    auto values = storage.get_all<T, QVector<T>>(sqlite_orm::order_by(&T::id).desc(), sqlite_orm::limit(1));
    if (values.empty()) {
        return QVariant();
    }

    return QVariant::fromValue(*values.rbegin());
}

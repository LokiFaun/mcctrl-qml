#include "sensordb.h"
#include <QDebug>
#include <QVector>

#include <sqlite_orm/sqlite_orm.h>

static std::string const TemperatureTable = "Temperature";
static std::string const PressureTable = "Pressure";

auto initStorage(QString const& connectionString)
{
    return sqlite_orm::make_storage(connectionString.toStdString(),
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
}

SensorDb::SensorDb(QObject* parent)
    : QObject(parent)
    , m_ConnectionString(":memory:")
{
}

void SensorDb::load()
{
    qDebug() << "Opening database: " << m_ConnectionString;
    auto storage = initStorage(m_ConnectionString);
    storage.sync_schema();
    if (storage.table_exists(TemperatureTable)) {
        try {
            auto temperatureList = storage.get_all<Temperature, QVector<Temperature>>();
            emit onLoadTemperature(temperatureList);
        } catch (std::system_error const& ex) {
            qWarning() << ex.what();
        }
    }

    if (storage.table_exists(PressureTable)) {
        try {
            auto pressureList = storage.get_all<Pressure, QVector<Pressure>>();
            emit onLoadPressure(pressureList);
        } catch (std::system_error const& ex) {
            qWarning() << ex.what();
        }
    }
}

QString SensorDb::connectionString() const
{
    return m_ConnectionString;
}

void SensorDb::setConnectionString(const QString& connectionString)
{
    m_ConnectionString = connectionString;
    load();
    emit connectionStringChanged(m_ConnectionString);
}

void SensorDb::addTemperature(QString const& time, double value)
{
    auto storage = initStorage(m_ConnectionString);
    if (!storage.table_exists(TemperatureTable)) {
        return;
    }

    auto id = storage.insert(Temperature{ 0, time.toStdString(), value });
    auto inserted = storage.get_no_throw<Temperature>(id);
    if (inserted) {
        emit onNewTemperature(*inserted);
    }
}

void SensorDb::addPressure(QString const& time, double value)
{
    auto storage = initStorage(m_ConnectionString);
    if (!storage.table_exists(PressureTable)) {
        return;
    }

    auto id = storage.insert(Pressure{ 0, time.toStdString(), value });
    auto inserted = storage.get_no_throw<Pressure>(id);
    if (inserted) {
        emit onNewPressure(*inserted);
    }
}

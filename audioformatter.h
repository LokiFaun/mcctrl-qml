#ifndef AUDIOFORMATTER_H
#define AUDIOFORMATTER_H

#include <QObject>

class AudioFormatter : public QObject
{
    Q_OBJECT
public:
    explicit AudioFormatter(QObject *parent = nullptr);

    Q_INVOKABLE QString format(QString const& fileName, QString const& format);
};

#endif // AUDIOFORMATTER_H

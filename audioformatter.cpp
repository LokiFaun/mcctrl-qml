#include "audioformatter.h"
#include <QDebug>
#include <taglib/fileref.h>

AudioFormatter::AudioFormatter(QObject* parent)
    : QObject(parent)
{
}

QString AudioFormatter::format(const QString& fileName, const QString& format)
{
    QString name(fileName);
    TagLib::FileRef mp3File(TagLib::FileName(name.replace("file:///", "").toStdString().c_str()));

    QString formatted(format);
    if (!mp3File.isNull() && mp3File.tag()) {
        qWarning() << "Artist: " << mp3File.tag()->artist().to8Bit().c_str();
        formatted = formatted.replace("%artist", QString::fromStdString(mp3File.tag()->artist().to8Bit()));
        formatted = formatted.replace("%track", QString::number(mp3File.tag()->track()));
        formatted = formatted.replace("%title", QString::fromStdString(mp3File.tag()->title().to8Bit()));
        formatted = formatted.replace("%album", QString::fromStdString(mp3File.tag()->album().to8Bit()));
    }

    return formatted;
}

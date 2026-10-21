#pragma once

#include <QString>

struct CompatReport {
    QString path;
    QString fileName;
    QString architecture;
    QString productName;
    QString nativeName;
    QString nativeUrl;
    QString problem;
    bool validPe = false;
    bool wineArchitecture = false;
    bool wineInstalled = false;
};

CompatReport inspectExecutable(const QString &path, bool wineInstalled);


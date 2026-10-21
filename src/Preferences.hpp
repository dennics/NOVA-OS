#pragma once
#include <KSharedConfig>
#include <QObject>
#include <QString>
class QProcess;

class Preferences final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString accent READ accent WRITE setAccent NOTIFY changed)
    Q_PROPERTY(QString motionProfile READ motionProfile WRITE setMotionProfile NOTIFY changed)
    Q_PROPERTY(bool reducedMotion READ reducedMotion WRITE setReducedMotion NOTIFY changed)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY changed)
    Q_PROPERTY(bool welcomeCompleted READ welcomeCompleted NOTIFY changed)
    Q_PROPERTY(int hoverDuration READ hoverDuration NOTIFY changed)
    Q_PROPERTY(int windowDuration READ windowDuration NOTIFY changed)
    Q_PROPERTY(int panelDuration READ panelDuration NOTIFY changed)
    Q_PROPERTY(bool animationsEnabled READ animationsEnabled NOTIFY changed)
    Q_PROPERTY(QString desktopError READ desktopError NOTIFY desktopErrorChanged)
    Q_PROPERTY(bool desktopBusy READ desktopBusy NOTIFY desktopBusyChanged)
public:
    explicit Preferences(QObject *parent = nullptr, QString configPath = {}, bool updateDesktop = true);
    QString accent() const { return m_accent; }
    QString motionProfile() const { return m_motion; }
    bool reducedMotion() const { return m_reduced; }
    QString language() const { return m_language; }
    bool welcomeCompleted() const { return m_welcome; }
    bool animationsEnabled() const { return !m_reduced && m_motion != QStringLiteral("minimal"); }
    int hoverDuration() const { return animationsEnabled() ? 120 : 0; }
    int windowDuration() const { return animationsEnabled() ? 180 : 0; }
    int panelDuration() const { return animationsEnabled() ? 220 : 0; }
    QString desktopError() const { return m_desktopError; }
    bool desktopBusy() const { return m_accentProcess != nullptr; }
    void setAccent(const QString &accent);
    void setMotionProfile(const QString &profile);
    void setReducedMotion(bool reduced);
    void setLanguage(const QString &language);
    Q_INVOKABLE void completeWelcome();
    void initializeSession(bool minimalEffects = false);
signals:
    void changed();
    void desktopErrorChanged();
    void desktopBusyChanged();
private:
    void save();
    void applyMotion();
    void applyAccent();
    void applyLanguage();
    KSharedConfig::Ptr m_config;
    QString m_accent = QStringLiteral("#57c7ff");
    QString m_motion = QStringLiteral("balanced");
    QString m_language = QStringLiteral("ro");
    bool m_reduced = false;
    bool m_welcome = false;
    bool m_updateDesktop;
    QString m_desktopError;
    QProcess *m_accentProcess = nullptr;
};


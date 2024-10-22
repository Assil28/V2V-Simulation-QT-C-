#ifndef MAINWINDOW_H
#define MAINWINDOW_H
#include <QMainWindow>
#include <QtQuickWidgets/QQuickWidget>
#include <QVariant>
#include <QtCore>
#include <QtGui>
#include <QtQuick>
#include <QList>
#include <QGeoCoordinate>
QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE
class MainWindow : public QMainWindow
{
    Q_OBJECT
public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();
private:
    Ui::MainWindow *ui;
    QList<QList<QGeoCoordinate>> generatedRoads;
    int m_pendingRoads;
    QSet<QString> collisionSet;

signals:
    void setCenterPosition(QVariant, QVariant);
    void setLocationMarking(QVariant, QVariant);
    void drawPathWithCoordinates(QVariant coordinates);
    void addCarPath(QVariant coordinates);
    void clearMap();
    void togglePauseSimulation();  // Added signal

public slots:
    void getRoute(double startLat, double startLong, double endLat, double endLong);
    void generateRandomRoads(int numberOfRoads);

    void onStartSimulationClicked();
    void onRestartClicked();
    void onPauseButtonClicked();  // Added slot
    void onSliderValueChanged(int value);
    void logCollision(int carIndex1, int carIndex2, qreal speed1, qreal frequency1, qreal speed2, qreal frequency2);
};
#endif // MAINWINDOW_H

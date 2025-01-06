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

    const double c = 3e8;  // Speed of light in m/s
    const double Pt = 1.0; // Transmit power in Watts
    const double Gt = 1.0; // Transmit antenna gain
    const double Gr = 1.0; // Receive antenna gain
    const double fc = 2.4e9; // Carrier frequency (2.4 GHz)

    // Helper methods for signal calculations
    double calculateReceivedPower(double distance);
    void checkSignalStrength(int carIndex1, int carIndex2, double distance);

signals:
    void setCenterPosition(QVariant, QVariant);
    void setLocationMarking(QVariant, QVariant);
    void drawPathWithCoordinates(QVariant coordinates);
    void addCarPath(QVariant coordinates);
    void clearMap();
    void toggleHexGrid();
    void togglePauseSimulation();  // Added signal

public slots:
    void getRoute(double startLat, double startLong, double endLat, double endLong);
    void generateRandomRoads(int numberOfRoads);

    void onStartSimulationClicked();
    void onRestartClicked();
    void onPauseButtonClicked();  // Added slot
    void onSliderValueChanged(int value);
    void logCollision(int carIndex1, int carIndex2, qreal speed1, qreal frequency1, qreal speed2, qreal frequency2);
private slots:
    void onToggleGridButtonClicked();
    void onToggleLogButtonClicked();
};
#endif // MAINWINDOW_H

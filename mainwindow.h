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

signals:
    void setCenterPosition(QVariant, QVariant);
    void setLocationMarking(QVariant, QVariant);
    void drawPathWithCoordinates(QVariant coordinates);
    void addCarPath(QVariant coordinates);
public slots:
    void getRoute(double startLat, double startLong, double endLat, double endLong);
    void generateRandomRoads(int numberOfRoads);

    void onStartSimulationClicked();
    void onRestartClicked();
    void onSliderValueChanged(int value);
};
#endif // MAINWINDOW_H

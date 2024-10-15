#ifndef MAINWINDOW_H
#define MAINWINDOW_H
#include <QMainWindow>
#include <QtQuickWidgets/QQuickWidget>
#include <QVariant>
#include <QtCore>
#include <QtGui>
#include <QtQuick>
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
protected:
    void keyPressEvent(QKeyEvent *event) override;  // Add this line
private:
    Ui::MainWindow *ui;
signals:
    void setCenterPosition(QVariant,QVariant);
    void setLocationMarking(QVariant,QVariant);
     void drawPathWithCoordinates(QVariant coordinates);
public slots:
    void getRoute(double startLat,double startLong,double endLat,double endLong);
    void startRouteSimulation();  // Add this line
     void generateRandomRoads(int numberOfRoads);  // Slot to generate random roads
};
#endif // MAINWINDOW_H

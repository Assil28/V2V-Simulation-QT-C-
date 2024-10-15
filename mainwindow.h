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

private:
    Ui::MainWindow *ui;


//ajouter
signals:
    void setCenterPosition(QVariant,QVariant);
    void setLocationMarking(QVariant,QVariant);

    //dissiner le chemin
    //void drawPathBetweenMarkers(QVariantList pathCoordinates);
    void drawPathWithCoordinates(QVariant coordinates);



public slots:
    void getRoute(double startLat, double startLong, double endLat, double endLong);

    // Declaration of the new function to generate random roads
    void generateRandomRoads(int numberOfRoads);  // Slot to generate random roads
};
#endif // MAINWINDOW_H

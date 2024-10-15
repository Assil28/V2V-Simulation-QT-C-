#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QKeyEvent>
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    ui->quickWidget_MapView->setSource(QUrl(QStringLiteral("qrc:/QmlMaps.qml")));
    ui->quickWidget_MapView->show();
    auto Obje = ui->quickWidget_MapView->rootObject();
    connect(this, SIGNAL(setCenterPosition(QVariant,QVariant)), Obje, SLOT(setCenterPosition(QVariant,QVariant)));
    // lat and long de Mulhouse
    emit setCenterPosition(47.7508, 7.3359);
}
MainWindow::~MainWindow()
{
    delete ui;
}
void MainWindow::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_Space) {
        startRouteSimulation();
    }
    QMainWindow::keyPressEvent(event);
}
void MainWindow::startRouteSimulation()
{
    QMetaObject::invokeMethod(ui->quickWidget_MapView->rootObject(), "requestRoute",
                              Q_ARG(QVariant, 47.752739), Q_ARG(QVariant, 7.336979),
                              Q_ARG(QVariant, 47.750983), Q_ARG(QVariant, 7.331639));
}

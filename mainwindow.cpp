#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    // Ajouter
    ui->quickWidget_MapView->setSource(QUrl(QStringLiteral("qrc:/QmlMaps.qml")));
    ui->quickWidget_MapView->show();

    auto Obje = ui->quickWidget_MapView->rootObject();

    connect(this,SIGNAL(setCenterPosition(QVariant,QVariant)),Obje,SLOT(setCenterPosition(QVariant,QVariant)));
    connect(this,SIGNAL(setLocationMarking(QVariant,QVariant)),Obje,SLOT(setLocationMarking(QVariant,QVariant)));

    // lat and long de Mulhouse
    emit setCenterPosition(47.7508,7.3359);
    emit setLocationMarking(47.7508,7.3359);

}

MainWindow::~MainWindow()
{
    delete ui;
}

#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QGeoCoordinate>
#include <QRandomGenerator>
#include <QtMath>
#include <QDebug>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    ui->quickWidget_MapView->setSource(QUrl(QStringLiteral("qrc:/QmlMaps.qml")));
    ui->quickWidget_MapView->show();

    auto Obje = ui->quickWidget_MapView->rootObject();

    connect(this, SIGNAL(setCenterPosition(QVariant,QVariant)), Obje, SLOT(setCenterPosition(QVariant,QVariant)));
    connect(this, SIGNAL(setLocationMarking(QVariant,QVariant)), Obje, SLOT(setLocationMarking(QVariant,QVariant)));
    connect(this, SIGNAL(setCarMarker(QVariant,QVariant)), Obje, SLOT(setCarMarker(QVariant,QVariant)));
    connect(this, SIGNAL(drawPathWithCoordinates(QVariantList)), Obje, SLOT(drawPathWithCoordinates(QVariantList)));

    emit setCenterPosition(47.729679, 7.321515);
    emit setLocationMarking(47.729679, 7.321515);
    emit setLocationMarking(47.7316239,7.3095028);

    getRoute(47.729679, 7.321515, 47.7316239, 7.3095028);

    qDebug() << "About to place cars on map";
    placeCarsOnMap();
    qDebug() << "Finished placing cars on map";
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::getRoute(double startLat, double startLong, double endLat, double endLong) {
    QNetworkAccessManager *manager = new QNetworkAccessManager(this);

    QString url = QString("http://router.project-osrm.org/route/v1/driving/%1,%2;%3,%4?overview=full&geometries=geojson")
                      .arg(startLong).arg(startLat).arg(endLong).arg(endLat);

    QNetworkRequest request(QUrl(url));

    QNetworkReply *reply = manager->get(QNetworkRequest(QUrl(url)));

    connect(reply, &QNetworkReply::finished, this, [=]() {
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument jsonResponse = QJsonDocument::fromJson(reply->readAll());
            QJsonObject jsonObj = jsonResponse.object();

            qDebug() << "Response JSON:" << jsonResponse.toJson(QJsonDocument::Indented);

            QJsonArray routes = jsonObj["routes"].toArray();
            if (!routes.isEmpty()) {
                QJsonObject route = routes[0].toObject();
                QJsonObject geometry = route["geometry"].toObject();
                QJsonArray coordinates = geometry["coordinates"].toArray();

                QVariantList pathCoordinates;
                for (const QJsonValue &coord : coordinates) {
                    QJsonArray coordPair = coord.toArray();
                    double lon = coordPair[0].toDouble();
                    double lat = coordPair[1].toDouble();
                    pathCoordinates.append(QVariant::fromValue(QGeoCoordinate(lat, lon)));
                }

                qDebug() << "Path coordinates:" << pathCoordinates;
                emit drawPathWithCoordinates(pathCoordinates);
            } else {
                qDebug() << "No routes found in response.";
            }
        } else {
            qDebug() << "Network error:" << reply->errorString();
        }

        reply->deleteLater();
    });
}

void MainWindow::placeCarsOnMap() {
    qDebug() << "Entering placeCarsOnMap function";
    double centerLat = 47.7508;
    double centerLon = 7.3359;

    double radius = 0.045;

    for (int i = 0; i < 10; ++i) {
        double r = radius * sqrt(QRandomGenerator::global()->generateDouble());
        double theta = QRandomGenerator::global()->generateDouble() * 2 * M_PI;

        double lat = centerLat + r * cos(theta);
        double lon = centerLon + r * sin(theta);

        qDebug() << "Emitting setCarMarker signal for car" << i << "at" << lat << lon;
        emit setCarMarker(lat, lon);
    }
    qDebug() << "Exiting placeCarsOnMap function";
}

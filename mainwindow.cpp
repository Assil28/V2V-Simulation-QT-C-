#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QGeoCoordinate>
#include <QtPositioning>
#include <cstdlib>
#include <ctime>
#include <random>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
    , m_pendingRoads(0)
{
    ui->setupUi(this);

    ui->quickWidget_MapView->setSource(QUrl(QStringLiteral("qrc:/QmlMaps.qml")));
    ui->quickWidget_MapView->show();

    QObject *rootObject = ui->quickWidget_MapView->rootObject();

    connect(this, SIGNAL(setCenterPosition(QVariant, QVariant)),
            rootObject, SLOT(setCenterPosition(QVariant, QVariant)));
    connect(this, SIGNAL(setLocationMarking(QVariant, QVariant)),
            rootObject, SLOT(setLocationMarking(QVariant, QVariant)));
    connect(this, SIGNAL(drawPathWithCoordinates(QVariant)),
            rootObject, SLOT(drawPathWithCoordinates(QVariant)));
    connect(this, SIGNAL(addCarPath(QVariant)),
            rootObject, SLOT(addCarPath(QVariant)));

    emit setCenterPosition(47.729679, 7.321515);

    std::srand(std::time(0));

    generateRandomRoads(5);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::generateRandomRoads(int numberOfRoads) {
    constexpr double MIN_LAT = 47.7200;
    constexpr double MAX_LAT = 47.7700;
    constexpr double MIN_LONG = 7.3000;
    constexpr double MAX_LONG = 7.3500;
    constexpr double MIN_DISTANCE = 0.01;

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<> lat_dist(MIN_LAT, MAX_LAT);
    std::uniform_real_distribution<> long_dist(MIN_LONG, MAX_LONG);

    m_pendingRoads = numberOfRoads;

    for (int i = 0; i < numberOfRoads; i++) {
        double startLat, startLong, endLat, endLong;
        double distance;

        do {
            startLat = lat_dist(gen);
            startLong = long_dist(gen);
            endLat = lat_dist(gen);
            endLong = long_dist(gen);
            distance = std::sqrt(std::pow((endLat - startLat) * 111.32, 2) +
                                 std::pow((endLong - startLong) * 111.32 * std::cos(startLat * M_PI / 180.0), 2));
        } while (distance < MIN_DISTANCE);

        emit setLocationMarking(startLat, startLong);
        emit setLocationMarking(endLat, endLong);

        getRoute(startLat, startLong, endLat, endLong);
    }
}

void MainWindow::getRoute(double startLat, double startLong, double endLat, double endLong)
{
    QNetworkAccessManager *manager = new QNetworkAccessManager(this);

    QString url = QString("http://router.project-osrm.org/route/v1/driving/%1,%2;%3,%4?overview=full&geometries=geojson")
                      .arg(startLong).arg(startLat).arg(endLong).arg(endLat);

    QUrl requestUrl(url);
    if (!requestUrl.isValid()) {
        qDebug() << "Invalid URL:" << url;
        return;
    }

    QNetworkRequest request(requestUrl);
    QNetworkReply *reply = manager->get(request);

    qDebug() << "Requesting URL:" << requestUrl.toString();

    connect(reply, &QNetworkReply::finished, this, [=]() {
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument jsonResponse = QJsonDocument::fromJson(reply->readAll());
            QJsonObject jsonObj = jsonResponse.object();

            QJsonArray routes = jsonObj["routes"].toArray();
            if (!routes.isEmpty()) {
                QJsonObject route = routes[0].toObject();
                QJsonObject geometry = route["geometry"].toObject();
                QJsonArray coordinates = geometry["coordinates"].toArray();

                QList<QGeoCoordinate> geoPathCoordinates;
                for (const QJsonValue &coord : coordinates) {
                    QJsonArray coordPair = coord.toArray();
                    double lon = coordPair[0].toDouble();
                    double lat = coordPair[1].toDouble();
                    geoPathCoordinates.append(QGeoCoordinate(lat, lon));
                }

                generatedRoads.append(geoPathCoordinates);
                emit drawPathWithCoordinates(QVariant::fromValue(geoPathCoordinates));

                // Add a car for this road immediately
                QVariantList roadCoordinates;
                for (const QGeoCoordinate &coord : geoPathCoordinates) {
                    roadCoordinates.append(QVariant::fromValue(coord));
                }
                emit addCarPath(QVariant::fromValue(roadCoordinates));
            } else {
                qDebug() << "No routes found in response.";
            }
        } else {
            qDebug() << "Network error:" << reply->errorString();
        }

        m_pendingRoads--;
        if (m_pendingRoads == 0) {
            qDebug() << "All roads generated and cars added.";
        }

        reply->deleteLater();
        manager->deleteLater();
    });
}

// Remove the addCarsToAllRoads() function as it's no longer needed

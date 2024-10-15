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

#include <cstdlib> // For random generation
#include <ctime>   // For seeding the random generator

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    // Set up QML view
    ui->quickWidget_MapView->setSource(QUrl(QStringLiteral("qrc:/QmlMaps.qml")));
    ui->quickWidget_MapView->show();

    // Get root object of QML
    QObject *rootObject = ui->quickWidget_MapView->rootObject();

    // Connect signals to QML slots
    connect(this, SIGNAL(setCenterPosition(QVariant, QVariant)),
            rootObject, SLOT(setCenterPosition(QVariant, QVariant)));
    connect(this, SIGNAL(setLocationMarking(QVariant, QVariant)),
            rootObject, SLOT(setLocationMarking(QVariant, QVariant)));
    connect(this, SIGNAL(drawPathWithCoordinates(QVariant)),
            rootObject, SLOT(drawPathWithCoordinates(QVariant)));

    // Set initial map center (Mulhouse)
    emit setCenterPosition(47.729679, 7.321515);

    // Seed the random generator
    std::srand(std::time(0));

    // Generate random roads
    generateRandomRoads(3);  // Generate 3 random roads
}

void MainWindow::generateRandomRoads(int numberOfRoads) {
    // Approximate bounding box for Mulhouse
    constexpr double MIN_LAT = 47.7200;
    constexpr double MAX_LAT = 47.7700;
    constexpr double MIN_LONG = 7.3000;
    constexpr double MAX_LONG = 7.3500;
    constexpr double MIN_DISTANCE = 0.01; // Minimum distance between start and end points (about 1 km)

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<> lat_dist(MIN_LAT, MAX_LAT);
    std::uniform_real_distribution<> long_dist(MIN_LONG, MAX_LONG);

    for (int i = 0; i < numberOfRoads; i++) {
        double startLat, startLong, endLat, endLong;
        double distance;

        do {
            // Generate random start coordinates
            startLat = lat_dist(gen);
            startLong = long_dist(gen);

            // Generate random end coordinates
            endLat = lat_dist(gen);
            endLong = long_dist(gen);

            // Calculate distance between start and end points
            distance = std::sqrt(std::pow((endLat - startLat) * 111.32, 2) +
                                 std::pow((endLong - startLong) * 111.32 * std::cos(startLat * M_PI / 180.0), 2));

        } while (distance < MIN_DISTANCE); // Ensure minimum distance is met

        // Add markers for start and end points
        emit setLocationMarking(startLat, startLong);  // Starting point of the route
        emit setLocationMarking(endLat, endLong);      // Ending point of the route

        // Fetch and draw the route automatically
        getRoute(startLat, startLong, endLat, endLong);
    }
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::getRoute(double startLat, double startLong, double endLat, double endLong)
{
    QNetworkAccessManager *manager = new QNetworkAccessManager(this);

    // Create URL for the request
    QString url = QString("http://router.project-osrm.org/route/v1/driving/%1,%2;%3,%4?overview=full&geometries=geojson")
                      .arg(startLong).arg(startLat).arg(endLong).arg(endLat);

    // Create and send the network request
    // Validate the URL before creating the request
    QUrl requestUrl(url);
    if (!requestUrl.isValid()) {
        qDebug() << "Invalid URL:" << url;
        return;  // Abort if the URL is invalid
    }

    QNetworkRequest request(requestUrl);
    QNetworkReply *reply = manager->get(request);  // Proceed with valid request

    // Log the request URL for debugging purposes
    qDebug() << "Requesting URL:" << requestUrl.toString();

    connect(reply, &QNetworkReply::finished, this, [=]() {
        if (reply->error() == QNetworkReply::NoError) {
            // Handle response data here
        } else {
            qDebug() << "Network error:" << reply->errorString();
        }
        reply->deleteLater();  // Make sure to clean up the reply after processing
    });


    // Handle the response when finished
    connect(reply, &QNetworkReply::finished, this, [=]() {
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument jsonResponse = QJsonDocument::fromJson(reply->readAll());
            QJsonObject jsonObj = jsonResponse.object();

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
                emit drawPathWithCoordinates(QVariant::fromValue(pathCoordinates));
            } else {
                qDebug() << "No routes found in response.";
            }
        } else {
            qDebug() << "Network error:" << reply->errorString();
        }

        reply->deleteLater();
    });
}

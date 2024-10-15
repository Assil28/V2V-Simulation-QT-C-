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

    // Add markers for start and end points
    emit setLocationMarking(47.729679, 7.321515);  // Starting point of the first route
    emit setLocationMarking(47.7316239, 7.3095028);  // Ending point of the first route

    // Fetch and draw the first route automatically
    getRoute(47.729679, 7.321515, 47.7316239, 7.3095028);

    // Add another route
    emit setLocationMarking(47.738000, 7.320000);  // Starting point of the second route
    emit setLocationMarking(47.740000, 7.325000);  // Ending point of the second route

    // Fetch and draw the second route automatically
    getRoute(47.738000, 7.320000, 47.740000, 7.325000);

     getRoute(47.729679, 7.321515,47.738000, 7.320000);

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

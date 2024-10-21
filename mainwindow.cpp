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
#include <QMessageBox>
//hhhh

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
    connect(this, SIGNAL(clearMap()),
            rootObject, SLOT(clearMap()));
    connect(this, SIGNAL(togglePauseSimulation()),
            rootObject, SLOT(togglePauseSimulation()));

    // Connect buttons and slider
    connect(ui->pushButton_2, &QPushButton::clicked, this, &MainWindow::onStartSimulationClicked);
    connect(ui->pushButton, &QPushButton::clicked, this, &MainWindow::onRestartClicked);
    connect(ui->pauseButton, &QPushButton::clicked, this, &MainWindow::onPauseButtonClicked);
    connect(ui->horizontalSlider, &QSlider::valueChanged, this, &MainWindow::onSliderValueChanged);



    emit setCenterPosition(47.729679, 7.321515);

    std::srand(std::time(0));

    //generateRandomRoads(5);
}

MainWindow::~MainWindow()
{
    delete ui;
}

/*******************Bouttons et slide bar**********************/
// Slot pour démarrer la simulation
void MainWindow::onStartSimulationClicked() {
    qDebug() << "Démarrer la simulation";

    // Get the number of cars from the numCars line edit
    bool ok;
    int numberOfCars = ui->numCars->text().toInt(&ok);
    if (!ok || numberOfCars <= 0) {
        qDebug() << "Invalid number of cars entered.";
        QMessageBox::warning(this, "Invalid Input", "Please enter a valid positive integer for the number of cars.");
        return;
    }

    // Start the simulation with the specified number of cars
    generateRandomRoads(numberOfCars);
}
void MainWindow::onPauseButtonClicked() {
    emit togglePauseSimulation();

    // Optional: Update button text
    QObject *rootObject = ui->quickWidget_MapView->rootObject();
    QVariant returnedValue;
    QMetaObject::invokeMethod(rootObject, "isSimulationPaused",
                              Q_RETURN_ARG(QVariant, returnedValue));
    bool simulationPaused = returnedValue.toBool();

    if (simulationPaused) {
        ui->pauseButton->setText("Resume");
    } else {
        ui->pauseButton->setText("Pause");
    }
}

// Slot pour redémarrer
void MainWindow::onRestartClicked() {
    qDebug() << "Redémarrage de la simulation";
    // Ajouter ici votre logique pour redémarrer la simulation

    // Clear the map
    generatedRoads.clear();
    emit clearMap();
    // Generate new roads
    // generateRandomRoads(5);

}

// Slot pour récupérer la valeur du slider
void MainWindow::onSliderValueChanged(int value) {
    qDebug() << "Valeur du slider:" << value;
    // Utilisez la valeur du slider ici
}



/*******************************************/


void MainWindow::generateRandomRoads(int numberOfRoads) {
    constexpr double MIN_LAT = 47.72196;
    constexpr double MAX_LAT = 47.74145;
    constexpr double MIN_LONG = 7.34672;
    constexpr double MAX_LONG = 7.29112;
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

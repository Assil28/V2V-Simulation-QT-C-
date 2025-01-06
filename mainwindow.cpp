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
#include <cmath>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
    , m_pendingRoads(0)
{
    ui->setupUi(this);

    ui->quickWidget_MapView->setSource(QUrl(QStringLiteral("qrc:/QmlMaps.qml")));
    ui->quickWidget_MapView->show();
    ui->panelWidget->setStyleSheet("background-color: rgba(0, 0, 0, 180);");
    QObject *rootObject = ui->quickWidget_MapView->rootObject();

    // Connect QML signals and slots
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
    connect(this, SIGNAL(toggleHexGrid()),
            rootObject, SLOT(toggleHexGrid()));

    // Connect UI elements (buttons and slider)
    connect(ui->pushButton_2, &QPushButton::clicked, this, &MainWindow::onStartSimulationClicked);
    connect(ui->pushButton, &QPushButton::clicked, this, &MainWindow::onRestartClicked);
    connect(ui->pauseButton, &QPushButton::clicked, this, &MainWindow::onPauseButtonClicked);
    connect(ui->horizontalSlider, &QSlider::valueChanged, this, &MainWindow::onSliderValueChanged);

    //Afficher et cacher
    connect(ui->toggleGridButton, &QPushButton::clicked, this, &MainWindow::onToggleGridButtonClicked);
    connect(ui->toggleLogButton, &QPushButton::clicked, this, &MainWindow::onToggleLogButtonClicked);

    // Set up QML context
    ui->quickWidget_MapView->rootContext()->setContextProperty("mainWindow", this);
    connect(ui->quickWidget_MapView->rootObject(), SIGNAL(collisionDetected(int,int,qreal,qreal,qreal,qreal)),
            this, SLOT(logCollision(int,int,qreal,qreal,qreal,qreal)));

    // Initialize map center
    emit setCenterPosition(47.729679, 7.321515);

    // Initialize random seed
    std::srand(std::time(0));

    // Configure the slider
    ui->horizontalSlider->setMinimum(0);
    ui->horizontalSlider->setMaximum(100);
    ui->horizontalSlider->setValue(50);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::onStartSimulationClicked() {
    qDebug() << "Starting simulation";

    bool ok;
    int numberOfCars = ui->numCars->text().toInt(&ok);
    if (!ok || numberOfCars <= 0) {
        qDebug() << "Invalid number of cars entered.";
        QMessageBox::warning(this, "Invalid Input", "Please enter a valid positive integer for the number of cars.");
        return;
    }

    generateRandomRoads(numberOfCars);
}

void MainWindow::onPauseButtonClicked() {
    emit togglePauseSimulation();

    QObject *rootObject = ui->quickWidget_MapView->rootObject();
    QVariant returnedValue;
    QMetaObject::invokeMethod(rootObject, "isSimulationPaused",
                              Q_RETURN_ARG(QVariant, returnedValue));
    bool simulationPaused = returnedValue.toBool();

    ui->pauseButton->setText(simulationPaused ? "Resume" : "Pause");
}

void MainWindow::onRestartClicked() {
    qDebug() << "Restarting simulation";
    generatedRoads.clear();
    emit clearMap();
    collisionSet.clear();
    ui->logListWidget->clear();
}

void MainWindow::onSliderValueChanged(int value) {
    double speedMultiplier = 0.1 + (value / 100.0) * 1.9;
    QObject *rootObject = ui->quickWidget_MapView->rootObject();
    QMetaObject::invokeMethod(rootObject, "updateCarSpeeds",
                              Q_ARG(QVariant, QVariant::fromValue(speedMultiplier)));
}

void MainWindow::onToggleGridButtonClicked() {
    emit toggleHexGrid();
}

// Slot function to toggle the visibility of the log panel (panelWidget)
void MainWindow::onToggleLogButtonClicked()
{
    // Check the current visibility status of panelWidget
    bool isVisible = ui->panelWidget->isVisible();

    // Toggle the visibility of panelWidget, which contains logListWidget
    ui->panelWidget->setVisible(!isVisible);

    // Update the button text based on the visibility state
    if (isVisible) {
        ui->toggleLogButton->setText("Afficher la Liste");
    } else {
        ui->toggleLogButton->setText("Cacher La liste");
    }
}

double MainWindow::calculateReceivedPower(double distance) {
    double lambda = c / fc;  // Wavelength
    double A = (lambda * lambda) / (4 * M_PI) * Gr;  // Effective antenna area

    // Calculate received power using the formula:
    // Pr = (PtGt/(4π*d^2)) * A = (λ^2/(4π*d)^2) * GtPtGr
    double Pr = (pow(lambda, 2) / pow(4 * M_PI * distance, 2)) * Gt * Pt * Gr;

    return Pr;
}

void MainWindow::checkSignalStrength(int carIndex1, int carIndex2, double distance) {
    double powerLevel = calculateReceivedPower(distance);
    double powerLeveldBm = 10 * log10(powerLevel * 1000);

    QString message = QString("Puissance du signal entre la voiture %1 et la voiture %2 :\n"
                              "Distance : %3 mètres\n"
                              "Puissance reçue : %4 dBm")
                          .arg(carIndex1 + 1)
                          .arg(carIndex2 + 1)
                          .arg(distance, 0, 'f', 1)
                          .arg(powerLeveldBm, 0, 'f', 2);

    if (powerLeveldBm > -90) {
        ui->logListWidget->addItem(message);
    }
}

void MainWindow::logCollision(int carIndex1, int carIndex2, qreal speed1, qreal frequency1, qreal speed2, qreal frequency2) {
    int minIndex = std::min(carIndex1, carIndex2);
    int maxIndex = std::max(carIndex1, carIndex2);
    QString pairKey = QString("%1-%2").arg(minIndex).arg(maxIndex);

    if (!collisionSet.contains(pairKey)) {
        collisionSet.insert(pairKey);

        // Get car positions
        QObject *rootObject = ui->quickWidget_MapView->rootObject();
        QVariant car1Pos, car2Pos;
        QMetaObject::invokeMethod(rootObject, "getCarPosition",
                                  Q_RETURN_ARG(QVariant, car1Pos),
                                  Q_ARG(QVariant, carIndex1));
        QMetaObject::invokeMethod(rootObject, "getCarPosition",
                                  Q_RETURN_ARG(QVariant, car2Pos),
                                  Q_ARG(QVariant, carIndex2));

        QGeoCoordinate pos1 = car1Pos.value<QGeoCoordinate>();
        QGeoCoordinate pos2 = car2Pos.value<QGeoCoordinate>();

        double distance = pos1.distanceTo(pos2);
        checkSignalStrength(carIndex1, carIndex2, distance);

        QString message = QString("Connexion détectée entre la voiture %1 et la voiture %2{\n"
                                  "  Voiture %1 :\n"
                                  "    Vitesse : %3 km/h\n"
                                  "    Fréquence : %4 GHz\n"
                                  "  Voiture %2 :\n"
                                  "    Vitesse : %5 km/h\n"
                                  "    Fréquence : %6 GHz\n"
                                  "}\n\n\n")
                              .arg(carIndex1 + 1)
                              .arg(carIndex2 + 1)
                              .arg(speed1, 0, 'f', 0)
                              .arg(frequency1*10, 0, 'f', 2)
                              .arg(speed2, 0, 'f', 0)
                              .arg(frequency2*10, 0, 'f', 2);

        ui->logListWidget->addItem(message);
    }
}

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

void MainWindow::getRoute(double startLat, double startLong, double endLat, double endLong) {
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



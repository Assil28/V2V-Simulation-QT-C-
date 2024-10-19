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

// Constructor for MainWindow
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)  // Initialize the UI
    , m_pendingRoads(0)  // Initialize pending roads counter
{
    ui->setupUi(this);  // Setup UI components

    // Load the QML file into the QuickWidget
    ui->quickWidget_MapView->setSource(QUrl(QStringLiteral("qrc:/QmlMaps.qml")));
    ui->quickWidget_MapView->show();  // Show the QuickWidget

    // Get the root object of the QML file to connect signals and slots
    QObject *rootObject = ui->quickWidget_MapView->rootObject();

    // Connect signals to corresponding slots in the QML object
    connect(this, SIGNAL(setCenterPosition(QVariant, QVariant)),
            rootObject, SLOT(setCenterPosition(QVariant, QVariant)));
    connect(this, SIGNAL(setLocationMarking(QVariant, QVariant)),
            rootObject, SLOT(setLocationMarking(QVariant, QVariant)));
    connect(this, SIGNAL(drawPathWithCoordinates(QVariant)),
            rootObject, SLOT(drawPathWithCoordinates(QVariant)));
    connect(this, SIGNAL(addCarPath(QVariant)),
            rootObject, SLOT(addCarPath(QVariant)));

    // Set the initial center position of the map
    emit setCenterPosition(47.729679, 7.321515);

    // Seed the random number generator
    std::srand(std::time(0));

    // Generate a specific number of random roads
    generateRandomRoads(5);
}

// Destructor for MainWindow
MainWindow::~MainWindow()
{
    delete ui;  // Cleanup UI components
}

// Function to generate random roads
void MainWindow::generateRandomRoads(int numberOfRoads) {
    // Define the geographic boundaries and minimum distance
    constexpr double MIN_LAT = 47.7200;
    constexpr double MAX_LAT = 47.7700;
    constexpr double MIN_LONG = 7.3000;
    constexpr double MAX_LONG = 7.3500;
    constexpr double MIN_DISTANCE = 0.01;  // Minimum distance between start and end points

    // Setup random number generation
    std::random_device rd;  // Random device for seeding
    std::mt19937 gen(rd());  // Mersenne Twister random number generator
    std::uniform_real_distribution<> lat_dist(MIN_LAT, MAX_LAT);  // Latitude distribution
    std::uniform_real_distribution<> long_dist(MIN_LONG, MAX_LONG);  // Longitude distribution

    m_pendingRoads = numberOfRoads;  // Set the number of pending roads to generate

    // Loop to generate specified number of random roads
    for (int i = 0; i < numberOfRoads; i++) {
        double startLat, startLong, endLat, endLong;
        double distance;

        // Generate random starting and ending coordinates for the roads
        do {
            startLat = lat_dist(gen);
            startLong = long_dist(gen);
            endLat = lat_dist(gen);
            endLong = long_dist(gen);
            // Calculate the distance between the start and end points
            distance = std::sqrt(std::pow((endLat - startLat) * 111.32, 2) +
                                 std::pow((endLong - startLong) * 111.32 * std::cos(startLat * M_PI / 180.0), 2));
        } while (distance < MIN_DISTANCE);  // Ensure the distance is greater than the minimum distance

        // Emit signals to mark the start and end locations on the map
        emit setLocationMarking(startLat, startLong);
        emit setLocationMarking(endLat, endLong);

        // Request a route between the two generated points
        getRoute(startLat, startLong, endLat, endLong);
    }
}

// Requests a driving route from a routing service and processes the response
void MainWindow::getRoute(double startLat, double startLong, double endLat, double endLong)
{
    // Create a network access manager to handle requests
    QNetworkAccessManager *manager = new QNetworkAccessManager(this);

    // Construct the URL for the routing service
    QString url = QString("http://router.project-osrm.org/route/v1/driving/%1,%2;%3,%4?overview=full&geometries=geojson")
                      .arg(startLong).arg(startLat).arg(endLong).arg(endLat);

    QUrl requestUrl(url);
    if (!requestUrl.isValid()) {
        qDebug() << "Invalid URL:" << url;  // Log an error if the URL is invalid
        return;
    }

    // Prepare and send the network request
    QNetworkRequest request(requestUrl);
    QNetworkReply *reply = manager->get(request);

    qDebug() << "Requesting URL:" << requestUrl.toString();  // Log the request URL

    // Connect the finished signal to handle the response
    connect(reply, &QNetworkReply::finished, this, [=]() {
        if (reply->error() == QNetworkReply::NoError) {  // Check for network errors
            // Parse the JSON response from the routing service
            QJsonDocument jsonResponse = QJsonDocument::fromJson(reply->readAll());
            QJsonObject jsonObj = jsonResponse.object();

            // Extract the routes array from the JSON response
            QJsonArray routes = jsonObj["routes"].toArray();
            if (!routes.isEmpty()) {
                QJsonObject route = routes[0].toObject();
                QJsonObject geometry = route["geometry"].toObject();
                QJsonArray coordinates = geometry["coordinates"].toArray();

                QList<QGeoCoordinate> geoPathCoordinates;  // List to hold the coordinates of the route
                for (const QJsonValue &coord : coordinates) {
                    QJsonArray coordPair = coord.toArray();
                    double lon = coordPair[0].toDouble();  // Longitude
                    double lat = coordPair[1].toDouble();  // Latitude
                    geoPathCoordinates.append(QGeoCoordinate(lat, lon));  // Add to list
                }

                generatedRoads.append(geoPathCoordinates);  // Store the generated road coordinates
                emit drawPathWithCoordinates(QVariant::fromValue(geoPathCoordinates));  // Emit signal to draw the path

                // Prepare a list of coordinates for the car to follow this road
                QVariantList roadCoordinates;
                for (const QGeoCoordinate &coord : geoPathCoordinates) {
                    roadCoordinates.append(QVariant::fromValue(coord));
                }
                emit addCarPath(QVariant::fromValue(roadCoordinates));  // Emit signal to add the car to the path
            } else {
                qDebug() << "No routes found in response.";  // Log if no routes are found
            }
        } else {
            qDebug() << "Network error:" << reply->errorString();  // Log any network errors
        }

        m_pendingRoads--;  // Decrease the count of pending roads
        if (m_pendingRoads == 0) {
            qDebug() << "All roads generated and cars added.";  // Log when all roads are processed
        }

        reply->deleteLater();  // Cleanup reply object
        manager->deleteLater();  // Cleanup network manager
    });
}

//welcome home

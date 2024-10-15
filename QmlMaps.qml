import QtQuick 2.15
import QtLocation 6.8
import QtQuick.Controls 2.15
import QtPositioning 6.8

import QtQuick.Layouts 1.15
import QtQuick.Shapes 1.15

Rectangle {
    id: window
    width: 800
    height: 600


    property double latitude: 47.7508
    property double longitude: 7.3359
    property int zoomLevel: 20 // Set default zoomLevel to 20

    property Component locationmarker: locmaker

    Plugin {
        id: googlemapview
        name: "osm"
    }

    Map {
        id: mapview
        anchors.fill: parent
        plugin: googlemapview
        center: QtPositioning.coordinate(window.latitude, window.longitude)
        zoomLevel: 17 // Bind zoomLevel to the Map's zoom level


    }

    function setCenterPosition(lati, longi) {
        mapview.pan(latitude - lati, longitude - longi);
        latitude = lati;
        longitude = longi;
    }

    // Position the marker at the location
    Component {
        id: locmaker
        MapQuickItem {
            id: markerImg
            anchorPoint.x: image.width / 2
            anchorPoint.y: image.height
            coordinate: QtPositioning.coordinate(0, 0) // Initial coordinate; will be overridden
            sourceItem: Image {
                id: image
                width: 20
                height: 20
                source: "https://www.pngarts.com/files/3/Map-Marker-Pin-PNG-Image-Background.png"
            }
        }
    }

    // Ajouter les grilles hexagonales par-dessus la carte
    HexagonalGrid {
        anchors.fill: parent
        z: 1  // Ensure it is above the map
    }
    // New property for the car
        property var carMarker: null

        // Function to create the car marker
        function createCarMarker(lat, lon) {
            if (carMarker === null) {
                carMarker = carMarkerComponent.createObject(mapview, {
                    coordinate: QtPositioning.coordinate(lat, lon)
                })
                mapview.addMapItem(carMarker)
            } else {
                carMarker.coordinate = QtPositioning.coordinate(lat, lon)
            }
        }

        // Component for the car marker
        Component {
            id: carMarkerComponent
            MapQuickItem {
                id: carMarker
                anchorPoint.x: image.width / 2
                anchorPoint.y: image.height
                sourceItem: Image {
                    id: carImage
                    width: 30
                    height: 30
                    source: "qrc:/car.svg" // Ensure this points to your car SVG
                }
            }
        }


        // Function to simulate car movement
        function simulateCarMovement(path) {
            let index = 0
            let timer = Qt.createQmlObject("import QtQml 2.15; Timer {}", window)
            timer.interval = 100 // Adjust for speed
            timer.repeat = true
            timer.triggered.connect(function() {
                if (index < path.length) {
                    let point = path[index]
                    createCarMarker(point.latitude, point.longitude)
                    index++
                } else {
                    timer.stop()
                }
            })
            timer.start()
        }

        // Function to request route
        function requestRoute(startLat, startLon, endLat, endLon) {
            let routeQuery = Qt.createQmlObject('import QtLocation 6.8; RouteQuery {}', window)
            routeQuery.addWaypoint(QtPositioning.coordinate(startLat, startLon))
            routeQuery.addWaypoint(QtPositioning.coordinate(endLat, endLon))
            routeQuery.travelModes = RouteQuery.CarTravel
            routeQuery.routeOptimizations = RouteQuery.FastestRoute

            let routeModel = Qt.createQmlObject('import QtLocation 6.8; RouteModel {}', window)
            routeModel.plugin = googlemapview
            routeModel.query = routeQuery

            routeModel.statusChanged.connect(function() {
                if (routeModel.status == RouteModel.Ready) {
                    if (routeModel.count > 0) {
                        let route = routeModel.get(0).path
                        simulateCarMovement(route)
                    }
                }
            })

            routeModel.update()
        }

        // Call this function to start the simulation
        Component.onCompleted: {
            requestRoute(47.752739, 7.336979, 47.750983, 7.331639)
        }
}

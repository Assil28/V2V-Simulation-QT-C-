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
    property int zoomLevel: 15 // Set default zoomLevel to 20

    property Component locationmarker: locmaker

    property var polylinePoints: []  // Holds the coordinates for the polyline

      property var polylines: []

    Plugin {
        id: googlemapview
        name: "osm"
    }

    Map {
        id: mapview
        anchors.fill: parent
        plugin: googlemapview
        center: QtPositioning.coordinate(window.latitude, window.longitude)
        zoomLevel: 15 // Bind zoomLevel to the Map's zoom level


        // Polyline to display the path between two points
               MapPolyline {
                   id: routeLine
                   line.width: 5
                   line.color: "red"
                   path: window.polylinePoints
               }

    // MouseArea for zooming and panning
           MouseArea {
                       anchors.fill: parent
                       drag.target: mapview
                       acceptedButtons: Qt.LeftButton | Qt.RightButton

                       onPressed: {
                           drag.startX = mouse.x;
                           drag.startY = mouse.y;
                       }

                       onReleased: {
                           mapview.panTo(mapview.center);
                       }

                       onPositionChanged: {
                           if (drag.active) {
                               var deltaLatitude = (mouseY - drag.startY) * 0.0001;
                               var deltaLongitude = (mouseX - drag.startX) * 0.0001;
                               mapview.center = QtPositioning.coordinate(latitude + deltaLatitude, longitude - deltaLongitude);
                           }
                       }

                       //Handle double-click for zooming
                          onDoubleClicked: {
                              zoomLevel += 1; // Zoom in
                              mapview.zoomLevel = zoomLevel; // Update the map's zoom level
                          }

                          // Handle mouse wheel for zooming
                          onWheel: function(event) {
                              if (event.angleDelta.y > 0) {
                                  zoomLevel += 1; // Zoom in
                              } else {
                                  zoomLevel -= 1; // Zoom out
                              }
                              mapview.zoomLevel = zoomLevel; // Update the map's zoom level
                          }
                   }
               }

    // Center the map
     function setCenterPosition(lati, longi) {
         mapview.center = QtPositioning.coordinate(lati, longi)
     }

     // Add a location marker
     function setLocationMarking(lati, longi) {
         var item = locationmarker.createObject(window, {
             coordinate: QtPositioning.coordinate(lati, longi)
         })
         if (item) {
             mapview.addMapItem(item)
             console.log("Marker created at:", lati, longi)
         }
     }

    // Draw the path using the coordinates from the backend

     function drawPathWithCoordinates(coordinates) {
         // Create the first polyline (thicker and transparent, for the center of the road)
         var transparentPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 10; line.color: "blue"; path: [] }', mapview);

         // Add coordinates to the transparent polyline
         for (var i = 0; i < coordinates.length; i++) {
             transparentPolyline.path.push(coordinates[i]);
         }

         // Add the transparent polyline to the map
         mapview.addMapItem(transparentPolyline);

         // Create the second polyline (thinner and blue, for the borders of the road)
         var borderPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 5; line.color: "white"; path: [] }', mapview);

         // Add coordinates to the blue polyline (borders)
         for (var i = 0; i < coordinates.length; i++) {
             borderPolyline.path.push(coordinates[i]);
         }

         // Add the blue border polyline to the map
         mapview.addMapItem(borderPolyline);
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

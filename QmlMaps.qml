import QtQuick 2.15
import QtLocation 6.8
import QtPositioning 6.8

// Main container for the map and UI
Rectangle {
    id: window
    width: 800
    height: 600

    // Properties to hold map coordinates and zoom level
    property double latitude: 47.729679
    property double longitude: 7.321515
    property int zoomLevel: 15

    // Component for the location marker
    property Component locationmarker: locmaker
    property var polylinePoints: []   // Holds points for a polyline route
    property var polylines: []        // Stores all polylines

    // Multiple cars and paths
    property var carPaths: []         // Stores coordinates for car routes
    property var carItems: []         // Stores car components
    property real animationDuration: 20000 // Time for a car to travel along its path

    // Plugin for displaying OpenStreetMap
    Plugin {
        id: mapPlugin
        name: "osm"
        PluginParameter {
            name: "osm.mapping.custom.host";
            value: "https://tile.openstreetmap.org/"
        }
    }

    // Map component to display OpenStreetMap tiles
    Map {
        id: mapview
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(window.latitude, window.longitude)
        zoomLevel: window.zoomLevel

        // Draws a polyline on the map to show routes
        MapPolyline {
            id: routeLine
            line.width: 5
            line.color: "red"
            path: window.polylinePoints  // Uses points defined in polylinePoints
            z: 1
        }

        // Handles user interaction with the map, including dragging and zooming
        MouseArea {
            anchors.fill: parent
            drag.target: mapview
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            // Stores initial drag position
            onPressed: function(mouse) {
                drag.startX = mouse.x;
                drag.startY = mouse.y;
            }

            // Adjusts the map's center based on drag
            onReleased: {
                mapview.pan(mapview.center);
            }

            onPositionChanged: {
                if (drag.active) {
                    var deltaLatitude = (mouseY - drag.startY) * 0.0001;
                    var deltaLongitude = (mouseX - drag.startX) * 0.0001;
                    mapview.center = QtPositioning.coordinate(
                        mapview.center.latitude + deltaLatitude,
                        mapview.center.longitude - deltaLongitude
                    );
                }
            }

            // Zoom in on double-click
            onDoubleClicked: {
                window.zoomLevel += 1;
                mapview.zoomLevel = window.zoomLevel;
            }

            // Zoom in/out with the mouse wheel
            onWheel: function(event) {
                if (event.angleDelta.y > 0) {
                    window.zoomLevel += 1;
                } else {
                    window.zoomLevel -= 1;
                }
                mapview.zoomLevel = window.zoomLevel;
            }
        }
    }

    // Sets the map center to the provided latitude and longitude
    function setCenterPosition(lati, longi) {
        mapview.center = QtPositioning.coordinate(lati, longi)
    }

    // Adds a location marker at the specified coordinates
    function setLocationMarking(lati, longi) {
        var item = locationmarker.createObject(window, {
            coordinate: QtPositioning.coordinate(lati, longi)
        })
        if (item) {
            mapview.addMapItem(item)
            console.log("Marker created at:", lati, longi)
        }
    }

    // Draws a polyline with a set of coordinates
    function drawPathWithCoordinates(coordinates) {
        var transparentPolyline = Qt.createQmlObject(
            'import QtLocation 5.0; MapPolyline { line.width: 10; line.color: "blue"; path: []; z: 1 }',
            mapview
        );
        var borderPolyline = Qt.createQmlObject(
            'import QtLocation 5.0; MapPolyline { line.width: 5; line.color: "white"; path: []; z: 1 }',
            mapview
        );

        for (var i = 0; i < coordinates.length; i++) {
            transparentPolyline.path.push(coordinates[i]);
            borderPolyline.path.push(coordinates[i]);
        }

        mapview.addMapItem(transparentPolyline);
        mapview.addMapItem(borderPolyline);
    }

    // Adds a car to follow a path defined by coordinates
    function addCarPath(coordinates) {
        carPaths.push(coordinates);
        var carItem = carComponent.createObject(mapview, {
            coordinate: coordinates[0],
            z: 2
        });
        mapview.addMapItem(carItem);
        carItems.push(carItem);

        // Starts animation for the car to move along the path
        animateCarAlongPath(carItems.length - 1);
    }

    // Animates the car along a pre-defined path
    function animateCarAlongPath(carIndex) {
        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', window);
        timer.interval = 100;   // Sets how often the car's position is updated
        timer.repeat = true;

        var pathIndex = 0;
        timer.triggered.connect(function() {
            if (pathIndex < carPaths[carIndex].length - 1) {
                var start = carPaths[carIndex][pathIndex];
                var end = carPaths[carIndex][pathIndex + 1];

                var progress = (timer.interval / animationDuration) * carPaths[carIndex].length;
                var interpolatedPosition = QtPositioning.coordinate(
                    start.latitude + (end.latitude - start.latitude) * progress,
                    start.longitude + (end.longitude - start.longitude) * progress
                );

                carItems[carIndex].coordinate = interpolatedPosition;

                pathIndex++;
            } else {
                timer.stop();  // Stops the timer when the car reaches the end of the path
            }
        });

        timer.start();  // Starts the animation timer
    }

    // Component definition for a car icon
    Component {
        id: carComponent
        MapQuickItem {
            anchorPoint.x: carImage.width / 2
            anchorPoint.y: carImage.height / 2
            sourceItem: Image {
                id: carImage
                source: "car.svg"
                width: 32
                height: 32
            }
        }
    }

    // Component for location marker image
    Component {
        id: locmaker
        MapQuickItem {
            id: markerImg
            anchorPoint.x: image.width / 2
            anchorPoint.y: image.height
            coordinate: QtPositioning.coordinate(0, 0)
            z: 2
            sourceItem: Image {
                id: image
                width: 20
                height: 20
                source: "https://www.pngarts.com/files/3/Map-Marker-Pin-PNG-Image-Background.png"
            }
        }
    }
}

//welcome home

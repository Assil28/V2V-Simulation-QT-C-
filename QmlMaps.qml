import QtQuick 2.15
import QtLocation 6.8
import QtPositioning 6.8

Rectangle {
    id: window
    width: 800
    height: 600

    property double latitude: 47.729679
    property double longitude: 7.321515
    property int zoomLevel: 15

    property Component locationmarker: locmaker
    property var polylinePoints: []
    property var polylines: []

    property bool simulationPaused: false
    property var pathIndices: []
    property var mapItems: []
    property var carItems: []
    property var carPaths: []
    property var carTimers: []

    property var carCircles: []
      property real baseCircleRadius: 50

    property real animationDuration: 20000 // 20 seconds to travel the whole path

    Plugin {
        id: mapPlugin
        name: "osm"
        PluginParameter { name: "osm.mapping.custom.host"; value: "https://tile.openstreetmap.org/" }
    }

    Map {
        id: mapview
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(window.latitude, window.longitude)
        zoomLevel: window.zoomLevel

        MapPolyline {
            id: routeLine
            line.width: 5
            line.color: "red"
            path: window.polylinePoints
            z: 1
        }

        MouseArea {
            anchors.fill: parent
            drag.target: mapview
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: function(mouse) {
                drag.startX = mouse.x;
                drag.startY = mouse.y;
            }

            onReleased: {
                mapview.pan(mapview.center);
            }

            onPositionChanged: {
                if (drag.active) {
                    var deltaLatitude = (mouseY - drag.startY) * 0.0001;
                    var deltaLongitude = (mouseX - drag.startX) * 0.0001;
                    mapview.center = QtPositioning.coordinate(mapview.center.latitude + deltaLatitude, mapview.center.longitude - deltaLongitude);
                }
            }

            onDoubleClicked: {
                window.zoomLevel += 1;
                mapview.zoomLevel = window.zoomLevel;
            }

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

    function setCenterPosition(lati, longi) {
        mapview.center = QtPositioning.coordinate(lati, longi)
    }

    function setLocationMarking(lati, longi) {
        var item = locationmarker.createObject(window, {
            coordinate: QtPositioning.coordinate(lati, longi)
        })
        if (item) {
            mapview.addMapItem(item)
            mapItems.push(item)
            console.log("Marker created at:", lati, longi)
        }
    }


    function drawPathWithCoordinates(coordinates) {
        var transparentPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 10; line.color: "blue"; path: []; z: 1 }', mapview);
        var borderPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 5; line.color: "white"; path: []; z: 1 }', mapview);

        for (var i = 0; i < coordinates.length; i++) {
            transparentPolyline.path.push(coordinates[i]);
            borderPolyline.path.push(coordinates[i]);
        }

        mapview.addMapItem(transparentPolyline);
        mapItems.push(transparentPolyline);
        mapview.addMapItem(borderPolyline);
        mapItems.push(borderPolyline);
    }


    function addCarPath(coordinates) {
        carPaths.push(coordinates);

        // Générer une vitesse aléatoire entre 1.5 et 3.0
        var speedMultiplier = 1.5 + Math.random() * 1.5;

        // Générer une fréquence aléatoire entre 0.5 et 2.0
        var frequency = 0.5 + Math.random() * 1.5;

        // Créer la voiture
        var carItem = carComponent.createObject(mapview, {
            coordinate: coordinates[0],
            z: 2
        });
        mapview.addMapItem(carItem);
        carItems.push(carItem);
        mapItems.push(carItem);

        // Créer le cercle autour de la voiture
        var circleRadius = baseCircleRadius * speedMultiplier * frequency;
        var circleItem = Qt.createQmlObject('import QtLocation 5.0; MapCircle {}', mapview);
        circleItem.center = coordinates[0];
        circleItem.radius = circleRadius;
        circleItem.color = Qt.rgba(1, 0, 0, 0.2);  // Rouge semi-transparent
        circleItem.border.width = 2;
        circleItem.border.color = "red";
        mapview.addMapItem(circleItem);
        carCircles.push(circleItem);
        mapItems.push(circleItem);

        // Démarrer l'animation pour cette voiture
        animateCarAlongPath(carItems.length - 1, speedMultiplier, frequency);
    }

    function animateCarAlongPath(carIndex, speedMultiplier, frequency) {
        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', window);

        timer.interval = 100 / speedMultiplier;
        timer.repeat = true;
        carTimers.push(timer);

        pathIndices[carIndex] = 0;  // Initialiser pathIndex pour cette voiture

        timer.triggered.connect(function() {
            var pathIndex = pathIndices[carIndex];
            if (pathIndex < carPaths[carIndex].length - 1) {
                var start = carPaths[carIndex][pathIndex];
                var end = carPaths[carIndex][pathIndex + 1];

                var progress = (timer.interval / (animationDuration * speedMultiplier)) * carPaths[carIndex].length;
                var interpolatedPosition = QtPositioning.coordinate(
                    start.latitude + (end.latitude - start.latitude) * progress,
                    start.longitude + (end.longitude - start.longitude) * progress
                );

                carItems[carIndex].coordinate = interpolatedPosition;
                carCircles[carIndex].center = interpolatedPosition;

                pathIndices[carIndex] = pathIndex + 1;  // Mettre à jour pathIndex
            } else {
                timer.stop();
            }
        });

        timer.start();
    }

    function togglePauseSimulation() {
        simulationPaused = !simulationPaused
        if (simulationPaused) {
            // Pause all timers
            for (var i = 0; i < carTimers.length; i++) {
                carTimers[i].stop()
            }
        } else {
            // Resume all timers
            for (var i = 0; i < carTimers.length; i++) {
                carTimers[i].start()
            }
        }
    }
    function isSimulationPaused() {
        return simulationPaused;
    }
    function clearMap() {
        // Stop and destroy car timers
        for (var i = 0; i < carTimers.length; i++) {
            carTimers[i].stop()
            carTimers[i].destroy()
        }
        carTimers = []

        // Remove and destroy map items
        for (var i = 0; i < mapItems.length; i++) {
            mapview.removeMapItem(mapItems[i])
            mapItems[i].destroy()
        }
        mapItems = []

        // Supprimer et détruire les cercles des voitures
               for (var i = 0; i < carCircles.length; i++) {
                   mapview.removeMapItem(carCircles[i]);
                   carCircles[i].destroy();
               }
               carCircles = [];

        // Clear other data
        carItems = []
        carPaths = []
    }

    Component {
        id: carComponent
        MapQuickItem {
            anchorPoint.x: carImage.width/2
            anchorPoint.y: carImage.height/2
            sourceItem: Image {
                id: carImage
                source: "car.svg"
                width: 32
                height: 32
            }
        }
    }

    Component {
        id: locmaker
        MapQuickItem {
            id: markerImg
            // anchorPoint.x: image.width / 2
            // anchorPoint.y: image.height
            // coordinate: QtPositioning.coordinate(0, 0)
            // z: 2
            // sourceItem: Image {
            //     id: image
            //     width: 20
            //     height: 20
            //     source: "https://www.pngarts.com/files/3/Map-Marker-Pin-PNG-Image-Background.png"
            // }
        }
    }

    HexagonalGrid {
       anchors.fill: parent
       z: 1  // Ensure it is above the map
   }
}

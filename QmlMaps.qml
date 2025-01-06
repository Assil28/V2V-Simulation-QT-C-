import QtQuick 2.15
import QtLocation 6.8
import QtPositioning 6.8

Rectangle {
    id: window
    width: 800
    height: 600

    // Propriétés de la carte
    property double latitude: 47.729679
    property double longitude: 7.321515
    property int zoomLevel: 15

    property Component locationmarker: locmaker
    property var polylinePoints: []
    property var polylines: []

    // Propriétés pour la simulation des voitures
    property var carSpeeds: []
    property var carFrequencies: []
    property bool simulationPaused: false
    property var pathIndices: []
    property var mapItems: []
    property var carItems: []
    property var carPaths: []
    property var carTimers: []
    property var carCircles: []
    property var carRadii: []
    property var carActive: []
    property real baseCircleRadius: 50
    property real animationDuration: 20000
    property var collisionPairs: []
    property real speedMultiplier: 1.0
    property bool hexGridVisible: true

    signal collisionDetected(int carIndex1, int carIndex2, real speed1, real frequency1, real speed2, real frequency2)

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

    // Fonctions pour gérer la carte et les éléments
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
        var transparentPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 5; line.color: "blue"; path: []; z: 1 }', mapview);
        var borderPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 2.5; line.color: "white"; path: []; z: 1 }', mapview);

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

        var speed = 60 + Math.random() * 60;
        var frequency = (3.5 + Math.random() * 12.5)/10;

        carSpeeds.push(speed);
        carFrequencies.push(frequency);
        carActive.push(true);

        var speedMultiplier = speed / 60;

        var carItem = carComponent.createObject(mapview, {
            coordinate: coordinates[0],
            z: 2
        });

        if (carItem === null) {
            console.error("Failed to create car item");
            return;
        }

        mapview.addMapItem(carItem);
        carItems.push(carItem);
        mapItems.push(carItem);

        var circleRadius = baseCircleRadius * speedMultiplier * frequency;
        var circleItem = Qt.createQmlObject('import QtLocation 5.0; MapCircle {}', mapview);
        circleItem.center = coordinates[0];
        circleItem.radius = circleRadius;
        circleItem.color = Qt.rgba(0, 1, 0, 0.2);
        circleItem.border.width = 2;
        circleItem.border.color = "green";
        mapview.addMapItem(circleItem);
        carCircles.push(circleItem);
        carRadii.push(circleRadius);
        carActive.push(true);
        mapItems.push(circleItem);

        animateCarAlongPath(carItems.length - 1, speedMultiplier, frequency);
        console.log("Car added at index:", carItems.length - 1);
    }

    function animateCarAlongPath(carIndex, speedMultiplier, frequency) {
        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', window);
        timer.interval = (100 / speedMultiplier) * (1 / window.speedMultiplier);
        timer.repeat = true;
        carTimers.push(timer);
        pathIndices[carIndex] = 0;
        timer.triggered.connect(function() {
            var pathIndex = pathIndices[carIndex];
            if (pathIndex < carPaths[carIndex].length - 1) {
                var start = carPaths[carIndex][pathIndex];
                var end = carPaths[carIndex][pathIndex + 1];
                var progress = (timer.interval * window.speedMultiplier / (animationDuration * speedMultiplier)) * carPaths[carIndex].length;
                var interpolatedPosition = QtPositioning.coordinate(
                    start.latitude + (end.latitude - start.latitude) * progress,
                    start.longitude + (end.longitude - start.longitude) * progress
                );
                carItems[carIndex].coordinate = interpolatedPosition;
                carCircles[carIndex].center = interpolatedPosition;
                checkCollisions(carIndex);
                pathIndices[carIndex] = pathIndex + 1;
            } else {
                timer.stop();
                carActive[carIndex] = false;
                carItems[carIndex].speed = 0; // Set the car's speed to 0
                checkCollisions();
            }
        });
        timer.start();
    }
    function updateCarSpeeds(multiplier) {
        speedMultiplier = multiplier;
        for (var i = 0; i < carTimers.length; i++) {
            if (carTimers[i].running) {
                carTimers[i].interval = (100 / speedMultiplier) * (1 / window.speedMultiplier);
            }
        }
    }
    function checkCollisions() {
        for (var i = 0; i < carCircles.length; i++) {
            carCircles[i].color = Qt.rgba(0, 1, 0, 0.2);
            carCircles[i].border.color = "green";
        }

        for (var i = 0; i < carCircles.length; i++) {
            for (var j = i + 1; j < carCircles.length; j++) {
                var distance = carCircles[i].center.distanceTo(carCircles[j].center);
                if (distance < (carRadii[i] + carRadii[j])) {
                    carCircles[i].color = Qt.rgba(1, 0, 0, 0.2);
                    carCircles[i].border.color = "red";
                    carCircles[j].color = Qt.rgba(1, 0, 0, 0.2);
                    carCircles[j].border.color = "red";

                    var pairKey = i < j ? i + "-" + j : j + "-" + i;

                    if (collisionPairs.indexOf(pairKey) === -1) {
                        collisionPairs.push(pairKey);
                        collisionDetected(i, j, carSpeeds[i], carFrequencies[i], carSpeeds[j], carFrequencies[j]);
                    }
                } else {
                    var pairKey = i < j ? i + "-" + j : j + "-" + i;
                    var index = collisionPairs.indexOf(pairKey);
                    if (index !== -1) {
                        collisionPairs.splice(index, 1);
                    }
                }
            }
        }
    }

    function togglePauseSimulation() {
        simulationPaused = !simulationPaused;
        if (simulationPaused) {
            for (var i = 0; i < carTimers.length; i++) {
                carTimers[i].stop();
            }
        } else {
            for (var i = 0; i < carTimers.length; i++) {
                carTimers[i].start();
            }
        }
    }
    function isSimulationPaused() {
        return simulationPaused
    }


    // Retourne les coordonnées de la voiture à l'index spécifié, ou null si l'index est invalide.
    function getCarPosition(carIndex) {
        if (carIndex < carItems.length) {
            return carItems[carIndex].coordinate;
        }
        return null;
    }



    function clearMap() {
        for (var i = 0; i < carTimers.length; i++) {
            carTimers[i].stop();
            carTimers[i].destroy();
        }
        carTimers = [];

        for (var i = 0; i < mapItems.length; i++) {
            mapview.removeMapItem(mapItems[i]);
            mapItems[i].destroy();
        }
        mapItems = [];

        for (var i = 0; i < carCircles.length; i++) {
            mapview.removeMapItem(carCircles[i]);
            carCircles[i].destroy();
        }
        carCircles = [];
        carRadii = [];
        carActive = [];
        carItems = [];
        carPaths = [];
        collisionPairs = [];
        if (hexGrid) {
            hexGrid.resetGrid();
        }
    }

    function toggleHexGrid() {
        hexGridVisible = !hexGridVisible;
    }

    onCollisionDetected: mainWindow.logCollision(carIndex1, carIndex2, speed1, frequency1, speed2, frequency2)

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

    Component {
        id: locmaker
        MapQuickItem {
            id: markerImg
        }
    }

    HexagonalGrid {
        id: hexGrid
        anchors.fill: parent
        z: 1
        visible: hexGridVisible
    }
}

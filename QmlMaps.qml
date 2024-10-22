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

        // Add missing property declarations
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
        signal collisionDetected(int carIndex1, int carIndex2, real speed1, real frequency1, real speed2, real frequency2)
        property var collisionPairs: []

    // vitesse
       property real speedMultiplier: 1.0
    // for show and hide grid
     property bool hexGridVisible: true

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

        /*MouseArea {
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

        }*/




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

        // Generate random speed between 60 and 120 km/h
        var speed = 60 + Math.random() * 60;
        var frequency = 0.5 + Math.random() * 1.5;

        carSpeeds.push(speed);
        carFrequencies.push(frequency);
        carActive.push(true);  // Initialize as active

        var speedMultiplier = speed / 60;

        // Create and add car
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

        // Create circle
        var circleRadius = baseCircleRadius * speedMultiplier * frequency;
        var circleItem = Qt.createQmlObject('import QtLocation 5.0; MapCircle {}', mapview);
        circleItem.center = coordinates[0];
        circleItem.radius = circleRadius;
        circleItem.color = Qt.rgba(1, 0, 0, 0.2);
        circleItem.border.width = 2;
        circleItem.border.color = "red";
        mapview.addMapItem(circleItem);
        carCircles.push(circleItem);
        carRadii.push(circleRadius);
        carActive.push(true);
        mapItems.push(circleItem);

        // Start animation
        animateCarAlongPath(carItems.length - 1, speedMultiplier, frequency);

        console.log("Car added at index:", carItems.length - 1);
    }


    function animateCarAlongPath(carIndex, speedMultiplier, frequency) {
        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', window);

        // Modify the interval calculation to use the global speedMultiplier
                timer.interval = (100 / speedMultiplier) * (1 / window.speedMultiplier);
        timer.repeat = true;
        carTimers.push(timer);

        pathIndices[carIndex] = 0;  // Initialiser pathIndex pour cette voiture

        timer.triggered.connect(function() {
            var pathIndex = pathIndices[carIndex];
            if (pathIndex < carPaths[carIndex].length - 1) {
                var start = carPaths[carIndex][pathIndex];
                var end = carPaths[carIndex][pathIndex + 1];

                // Adjust progress calculation to use the global speedMultiplier
           var progress = (timer.interval * window.speedMultiplier / (animationDuration * speedMultiplier)) * carPaths[carIndex].length;
           var interpolatedPosition = QtPositioning.coordinate(
               start.latitude + (end.latitude - start.latitude) * progress,
               start.longitude + (end.longitude - start.longitude) * progress
           );

                carItems[carIndex].coordinate = interpolatedPosition;
                carCircles[carIndex].center = interpolatedPosition;

                checkCollisions(carIndex);

                pathIndices[carIndex] = pathIndex + 1;  // Mettre à jour pathIndex
            } else {
                timer.stop();
                carActive[carIndex] = false;  // Marquer la voiture comme inactive
                checkCollisions();
            }
        });

        timer.start();
    }


    // Add a function to update all car speeds
    function updateCarSpeeds(multiplier) {
        speedMultiplier = multiplier;
        for (var i = 0; i < carTimers.length; i++) {
            if (carTimers[i].running) {
                carTimers[i].interval = (100 / speedMultiplier) * (1 / window.speedMultiplier);
            }
        }
    }


    function checkCollisions() {
        // Reset all car colors to the default (red) at the start
        for (var i = 0; i < carCircles.length; i++) {
            carCircles[i].color = Qt.rgba(1, 0, 0, 0.2);  // Red semi-transparent
            carCircles[i].border.color = "red";
        }

        // Check for collisions between all cars
        for (var i = 0; i < carCircles.length; i++) {
            for (var j = i + 1; j < carCircles.length; j++) {
                var distance = carCircles[i].center.distanceTo(carCircles[j].center);

                if (distance < (carRadii[i] + carRadii[j])) {
                    // Collision detected
                    carCircles[i].color = Qt.rgba(0, 1, 0, 0.2);  // Green semi-transparent
                    carCircles[i].border.color = "green";
                    carCircles[j].color = Qt.rgba(0, 1, 0, 0.2);  // Green semi-transparent
                    carCircles[j].border.color = "green";

                    // Create a unique key for this collision pair
                    var pairKey = i < j ? i + "-" + j : j + "-" + i;

                    // Emit the collisionDetected signal if this collision hasn't been reported yet
                    if (collisionPairs.indexOf(pairKey) === -1) {
                        collisionPairs.push(pairKey);
                        collisionDetected(
                            i,
                            j,
                            carSpeeds[i],
                            carFrequencies[i],
                            carSpeeds[j],
                            carFrequencies[j]
                        );
                    }
                } else {
                    // If no collision for this pair, remove it from the collisionPairs if previously detected
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
                carRadii = [];
        carActive = [];
        // Clear other data
        carItems = []
        carPaths = []
        collisionPairs = [];
        if (hexGrid) {
          hexGrid.resetGrid()
      }
    }
    //for hide and show grid
    function toggleHexGrid() {
        hexGridVisible = !hexGridVisible;
    }
    onCollisionDetected: mainWindow.logCollision(carIndex1, carIndex2, speed1, frequency1, speed2, frequency2)
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
       id: hexGrid
       anchors.fill: parent
       z: 1
       visible : hexGridVisible
   }
}

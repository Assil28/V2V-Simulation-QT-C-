// Importation des modules Qt nécessaires
import QtQuick 2.15          // Module de base pour les interfaces QML
import QtLocation 6.8        // Module pour les fonctionnalités de cartographie
import QtPositioning 6.8     // Module pour le positionnement géographique

Rectangle {
    id: window
    width: 800
    height: 600

    // Propriétés de base pour la carte
    property double latitude: 47.729679     // Latitude initiale de la carte
    property double longitude: 7.321515     // Longitude initiale de la carte
    property int zoomLevel: 15             // Niveau de zoom initial

    // Propriétés pour les marqueurs et les chemins
    property Component locationmarker: locmaker  // Composant pour les marqueurs de position
    property var polylinePoints: []             // Points pour dessiner les lignes sur la carte
    property var polylines: []                  // Collection de polylines

    // Propriétés pour la simulation de voitures
    property var carSpeeds: []                  // Vitesses des voitures
    property var carFrequencies: []             // Fréquences des voitures
    property bool simulationPaused: false       // État de pause de la simulation
    property var pathIndices: []                // Indices des chemins pour chaque voiture
    property var mapItems: []                   // Éléments affichés sur la carte
    property var carItems: []                   // Objets voitures
    property var carPaths: []                   // Chemins des voitures
    property var carTimers: []                  // Timers pour l'animation des voitures

    // Propriétés pour les cercles de collision
    property var carCircles: []                 // Cercles autour des voitures
    property var carRadii: []                   // Rayons des cercles
    property var carActive: []                  // État d'activité des voitures
    property real baseCircleRadius: 50          // Rayon de base pour les cercles

    // Propriétés pour l'animation et les collisions
    property real animationDuration: 20000      // Durée de l'animation en millisecondes
    signal collisionDetected(int carIndex1, int carIndex2, real speed1, real frequency1, real speed2, real frequency2)
    property var collisionPairs: []             // Paires de voitures en collision

    // Propriétés pour le contrôle de la simulation
    property real speedMultiplier: 1.0          // Multiplicateur de vitesse global
    property bool hexGridVisible: true          // Visibilité de la grille hexagonale

    // Configuration du plugin de carte OpenStreetMap
    Plugin {
        id: mapPlugin
        name: "osm"
        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "https://tile.openstreetmap.org/"
        }
    }

    // Composant principal de la carte
    Map {
        id: mapview
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(window.latitude, window.longitude)
        zoomLevel: window.zoomLevel

        // Ligne pour tracer les routes
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

    // Fonctions de manipulation de la carte
    function setCenterPosition(lati, longi) {
        // Centre la carte sur les coordonnées spécifiées
        mapview.center = QtPositioning.coordinate(lati, longi)
    }

    function setLocationMarking(lati, longi) {
        // Ajoute un marqueur à la position spécifiée
        var item = locationmarker.createObject(window, {
            coordinate: QtPositioning.coordinate(lati, longi)
        })
        if (item) {
            mapview.addMapItem(item)
            mapItems.push(item)
            console.log("Marker created at:", lati, longi)
        }
    }

    // Fonction pour dessiner un chemin avec des coordonnées
    function drawPathWithCoordinates(coordinates) {
        // Crée deux polylines : une transparente et une bordure
        var transparentPolyline = Qt.createQmlObject(
            'import QtLocation 5.0; MapPolyline { line.width: 5; line.color: "blue"; path: []; z: 1 }',
            mapview
        );
        var borderPolyline = Qt.createQmlObject(
            'import QtLocation 5.0; MapPolyline { line.width: 2.5; line.color: "white"; path: []; z: 1 }',
            mapview
        );

        // Ajoute les coordonnées aux deux polylines
        for (var i = 0; i < coordinates.length; i++) {
            transparentPolyline.path.push(coordinates[i]);
            borderPolyline.path.push(coordinates[i]);
        }

        // Ajoute les polylines à la carte
        mapview.addMapItem(transparentPolyline);
        mapItems.push(transparentPolyline);
        mapview.addMapItem(borderPolyline);
        mapItems.push(borderPolyline);
    }

    // Fonction pour ajouter une voiture et son chemin
    function addCarPath(coordinates) {
        carPaths.push(coordinates);

        // Génère des valeurs aléatoires pour la vitesse et la fréquence
        var speed = 60 + Math.random() * 60;  // Vitesse entre 60 et 120 km/h
        var frequency = 0.5 + Math.random() * 1.5;

        carSpeeds.push(speed);
        carFrequencies.push(frequency);
        carActive.push(true);

        var speedMultiplier = speed / 60;

        // Crée et ajoute la voiture sur la carte
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

        // Crée le cercle de collision autour de la voiture
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

        // Démarre l'animation de la voiture
        animateCarAlongPath(carItems.length - 1, speedMultiplier, frequency);
    }

    // Fonction pour animer une voiture le long de son chemin
    function animateCarAlongPath(carIndex, speedMultiplier, frequency) {
        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', window);
        timer.interval = (100 / speedMultiplier) * (1 / window.speedMultiplier);
        timer.repeat = true;
        carTimers.push(timer);

        pathIndices[carIndex] = 0;

        timer.triggered.connect(function() {
            var pathIndex = pathIndices[carIndex];
            if (pathIndex < carPaths[carIndex].length - 1) {
                // Calcule la position interpolée entre deux points
                var start = carPaths[carIndex][pathIndex];
                var end = carPaths[carIndex][pathIndex + 1];
                var progress = (timer.interval * window.speedMultiplier / (animationDuration * speedMultiplier)) * carPaths[carIndex].length;
                var interpolatedPosition = QtPositioning.coordinate(
                    start.latitude + (end.latitude - start.latitude) * progress,
                    start.longitude + (end.longitude - start.longitude) * progress
                );

                // Met à jour la position de la voiture et de son cercle
                carItems[carIndex].coordinate = interpolatedPosition;
                carCircles[carIndex].center = interpolatedPosition;

                // Vérifie les collisions
                checkCollisions(carIndex);

                pathIndices[carIndex] = pathIndex + 1;
            } else {
                // Arrête l'animation quand le chemin est terminé
                timer.stop();
                carActive[carIndex] = false;
                checkCollisions();
            }
        });

        timer.start();
    }

    // Fonction pour mettre à jour la vitesse de toutes les voitures
    function updateCarSpeeds(multiplier) {
        speedMultiplier = multiplier;
        for (var i = 0; i < carTimers.length; i++) {
            if (carTimers[i].running) {
                carTimers[i].interval = (100 / speedMultiplier) * (1 / window.speedMultiplier);
            }
        }
    }

    // Fonction pour détecter les collisions entre les voitures
    function checkCollisions() {
        // Réinitialise les couleurs des cercles
        for (var i = 0; i < carCircles.length; i++) {
            carCircles[i].color = Qt.rgba(1, 0, 0, 0.2);
            carCircles[i].border.color = "red";
        }

        // Vérifie les collisions entre toutes les paires de voitures
        for (var i = 0; i < carCircles.length; i++) {
            for (var j = i + 1; j < carCircles.length; j++) {
                var distance = carCircles[i].center.distanceTo(carCircles[j].center);

                if (distance < (carRadii[i] + carRadii[j])) {
                    // Collision détectée : change la couleur des cercles
                    carCircles[i].color = Qt.rgba(0, 1, 0, 0.2);
                    carCircles[i].border.color = "green";
                    carCircles[j].color = Qt.rgba(0, 1, 0, 0.2);
                    carCircles[j].border.color = "green";

                    // Gère l'émission du signal de collision
                    var pairKey = i < j ? i + "-" + j : j + "-" + i;
                    if (collisionPairs.indexOf(pairKey) === -1) {
                        collisionPairs.push(pairKey);
                        collisionDetected(
                            i, j,
                            carSpeeds[i], carFrequencies[i],
                            carSpeeds[j], carFrequencies[j]
                        );
                    }
                } else {
                    // Supprime la paire de collision si elle n'est plus en collision
                    var pairKey = i < j ? i + "-" + j : j + "-" + i;
                    var index = collisionPairs.indexOf(pairKey);
                    if (index !== -1) {
                        collisionPairs.splice(index, 1);
                    }
                }
            }
        }
    }

    // Fonctions de contrôle de la simulation
    function togglePauseSimulation() {
        simulationPaused = !simulationPaused
        if (simulationPaused) {
            // Arrête tous les timers
            for (var i = 0; i < carTimers.length; i++) {
                carTimers[i].stop()
            }
        } else {
            // Redémarre tous les timers
            for (var i = 0; i < carTimers.length; i++) {
                carTimers[i].start()
            }
        }
    }

    function isSimulationPaused() {
        return simulationPaused;
    }

    // Fonction pour nettoyer la carte
    function clearMap() {
        // Arrête et détruit tous les timers
        for (var i = 0; i < carTimers.length; i++) {
            carTimers[i].stop()
            carTimers[i].destroy()
        }
        carTimers = []

        // Supprime et détruit tous les éléments de la carte
        for (var i = 0; i < mapItems.length; i++) {
            mapview.removeMapItem(mapItems[i])
            mapItems[i].destroy()
        }
        mapItems = []

        // Nettoie les cercles des voitures
        for (var i = 0; i < carCircles.length; i++) {
            mapview.removeMapItem(carCircles[i]);
            carCircles[i].destroy();
        }

        // Réinitialise toutes les collections
        carCircles = [];
        carRadii = [];
        carActive = [];
        carItems = []
        carPaths = []
        collisionPairs = [];

        if (hexGrid) {
            hexGrid.resetGrid()
        }
    }

    // Fonction pour afficher/masquer la grille hexagonale
    function toggleHexGrid() {
        hexGridVisible = !hexGridVisible;
    }

    // Gestion des collisions
    onCollisionDetected: mainWindow.logCollision(carIndex1, carIndex2, speed1, frequency1, speed2, frequency2)

    // Composant pour représenter les voitures
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

    // Composant pour les marqueurs de position
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

    // Composant de grille hexagonale
    HexagonalGrid {
        id: hexGrid
        anchors.fill: parent
        z: 1
        visible: hexGridVisible
    }
}

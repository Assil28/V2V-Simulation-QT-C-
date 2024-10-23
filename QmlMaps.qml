import QtQuick 2.15
import QtLocation 6.8
import QtPositioning 6.8

Rectangle {
    id: window
    width: 800
    height: 600

    // ==================== Property Declarations ====================
    // Map properties
    property double latitude: 47.729679
    property double longitude: 7.321515
    property int zoomLevel: 15
    property var polylinePoints: []
    property var mapItems: []
    property Component locationmarker: locmaker

    // Car simulation properties
    property var carSpeeds: []
    property var carFrequencies: []
    property var carActive: []
    property var carItems: []
    property var carPaths: []
    property var carTimers: []
    property var carCircles: []
    property var carRadii: []
    property var pathIndices: []
    property var collisionPairs: []
    property real baseCircleRadius: 50
    property real animationDuration: 20000
    property real speedMultiplier: 1.0
    property bool simulationPaused: false

    // Grid properties
    property bool hexGridVisible: true

    // ==================== Signals ====================
    signal collisionDetected(int carIndex1, int carIndex2, real speed1, real frequency1,
                           real speed2, real frequency2)

    // ==================== Map Configuration ====================
    Plugin {
        id: mapPlugin
        name: "osm"
        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "https://tile.openstreetmap.org/"
        }
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
    }

    // ==================== Components ====================
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
        }
    }

    HexagonalGrid {
        id: hexGrid
        anchors.fill: parent
        z: 1
        visible: hexGridVisible
    }

    // ==================== Map Functions ====================
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
        var transparentPolyline = Qt.createQmlObject(
            'import QtLocation 5.0; MapPolyline { line.width: 5; line.color: "blue"; path: []; z: 1 }',
            mapview
        )
        var borderPolyline = Qt.createQmlObject(
            'import QtLocation 5.0; MapPolyline { line.width: 2.5; line.color: "white"; path: []; z: 1 }',
            mapview
        )

        for (var i = 0; i < coordinates.length; i++) {
            transparentPolyline.path.push(coordinates[i])
            borderPolyline.path.push(coordinates[i])
        }

        mapview.addMapItem(transparentPolyline)
        mapItems.push(transparentPolyline)
        mapview.addMapItem(borderPolyline)
        mapItems.push(borderPolyline)
    }

    // ==================== Car Functions ====================
    function addCarPath(coordinates) {
        carPaths.push(coordinates)

        // Generate random properties
        var speed = 60 + Math.random() * 60
        var frequency = 0.5 + Math.random() * 1.5
        var speedMultiplier = speed / 60

        // Add car properties
        carSpeeds.push(speed)
        carFrequencies.push(frequency)
        carActive.push(true)

        // Create car item
        var carItem = carComponent.createObject(mapview, {
            coordinate: coordinates[0],
            z: 2
        })

        if (!carItem) {
            console.error("Failed to create car item")
            return
        }

        // Add car to map
        mapview.addMapItem(carItem)
        carItems.push(carItem)
        mapItems.push(carItem)

        // Create and add circle
        var circleRadius = baseCircleRadius * speedMultiplier * frequency
        var circleItem = Qt.createQmlObject('import QtLocation 5.0; MapCircle {}', mapview)
        circleItem.center = coordinates[0]
        circleItem.radius = circleRadius
        circleItem.color = Qt.rgba(1, 0, 0, 0.2)
        circleItem.border.width = 2
        circleItem.border.color = "red"

        mapview.addMapItem(circleItem)
        carCircles.push(circleItem)
        carRadii.push(circleRadius)
        mapItems.push(circleItem)

        // Start animation
        animateCarAlongPath(carItems.length - 1, speedMultiplier, frequency)
        console.log("Car added at index:", carItems.length - 1)
    }

    function animateCarAlongPath(carIndex, speedMultiplier, frequency) {
        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', window)
        timer.interval = (100 / speedMultiplier) * (1 / window.speedMultiplier)
        timer.repeat = true
        carTimers.push(timer)
        pathIndices[carIndex] = 0

        timer.triggered.connect(function() {
            var pathIndex = pathIndices[carIndex]
            if (pathIndex < carPaths[carIndex].length - 1) {
                var start = carPaths[carIndex][pathIndex]
                var end = carPaths[carIndex][pathIndex + 1]

                var progress = (timer.interval * window.speedMultiplier /
                             (animationDuration * speedMultiplier)) * carPaths[carIndex].length
                var interpolatedPosition = QtPositioning.coordinate(
                    start.latitude + (end.latitude - start.latitude) * progress,
                    start.longitude + (end.longitude - start.longitude) * progress
                )

                carItems[carIndex].coordinate = interpolatedPosition
                carCircles[carIndex].center = interpolatedPosition
                checkCollisions(carIndex)
                pathIndices[carIndex] = pathIndex + 1
            } else {
                timer.stop()
                carActive[carIndex] = false
                checkCollisions()
            }
        })

        timer.start()
    }

    // ==================== Collision Functions ====================
    function checkCollisions() {
        // Reset all circles to default color
        for (var i = 0; i < carCircles.length; i++) {
            carCircles[i].color = Qt.rgba(1, 0, 0, 0.2)
            carCircles[i].border.color = "red"
        }

        // Check collisions between all active cars
        for (var i = 0; i < carCircles.length; i++) {
            for (var j = i + 1; j < carCircles.length; j++) {
                if (!carActive[i] || !carActive[j]) continue

                var distance = carCircles[i].center.distanceTo(carCircles[j].center)
                if (distance < (carRadii[i] + carRadii[j])) {
                    handleCollision(i, j)
                } else {
                    removeCollisionPair(i, j)
                }
            }
        }
    }

    function handleCollision(i, j) {
        // Update circle colors
        carCircles[i].color = Qt.rgba(0, 1, 0, 0.2)
        carCircles[i].border.color = "green"
        carCircles[j].color = Qt.rgba(0, 1, 0, 0.2)
        carCircles[j].border.color = "green"

        // Create collision pair key
        var pairKey = i < j ? i + "-" + j : j + "-" + i

        // Emit collision signal if new
        if (collisionPairs.indexOf(pairKey) === -1) {
            collisionPairs.push(pairKey)
            collisionDetected(i, j, carSpeeds[i], carFrequencies[i],
                            carSpeeds[j], carFrequencies[j])
        }
    }

    function removeCollisionPair(i, j) {
        var pairKey = i < j ? i + "-" + j : j + "-" + i
        var index = collisionPairs.indexOf(pairKey)
        if (index !== -1) {
            collisionPairs.splice(index, 1)
        }
    }

    // ==================== Simulation Control Functions ====================
    function updateCarSpeeds(multiplier) {
        speedMultiplier = multiplier
        for (var i = 0; i < carTimers.length; i++) {
            if (carTimers[i].running) {
                carTimers[i].interval = (100 / speedMultiplier) * (1 / window.speedMultiplier)
            }
        }
    }

    function togglePauseSimulation() {
        simulationPaused = !simulationPaused
        for (var i = 0; i < carTimers.length; i++) {
            if (simulationPaused) {
                carTimers[i].stop()
            } else {
                carTimers[i].start()
            }
        }
    }

    function isSimulationPaused() {
        return simulationPaused
    }

    function toggleHexGrid() {
        hexGridVisible = !hexGridVisible
    }

    function clearMap() {
        // Stop and clean up timers
        for (var i = 0; i < carTimers.length; i++) {
            carTimers[i].stop()
            carTimers[i].destroy()
        }

        // Remove and clean up map items
        for (var i = 0; i < mapItems.length; i++) {
            mapview.removeMapItem(mapItems[i])
            mapItems[i].destroy()
        }

        // Remove and clean up car circles
        for (var i = 0; i < carCircles.length; i++) {
            mapview.removeMapItem(carCircles[i])
            carCircles[i].destroy()
        }

        // Reset all arrays
        carTimers = []
        mapItems = []
        carCircles = []
        carRadii = []
        carActive = []
        carItems = []
        carPaths = []
        collisionPairs = []

        // Reset hex grid if exists
        if (hexGrid) {
            hexGrid.resetGrid()
        }
    }

    // Connect collision signal to main window
    onCollisionDetected: mainWindow.logCollision(carIndex1, carIndex2, speed1, frequency1,
                                               speed2, frequency2)
}

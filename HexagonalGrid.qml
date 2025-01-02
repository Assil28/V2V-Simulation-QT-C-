import QtQuick 2.15

Item {
    id: hexGrid
    anchors.fill: parent

    // Propriétés de base
    property int baseRadius: 30
    property int radius: Math.max(20, Math.min(60, baseRadius * Math.pow(2, (mapview.zoomLevel - 15) / 3)))
    property var hexagonCarCounts: ({})
    property var mapCenter: mapview.center
    property real mapZoomLevel: mapview.zoomLevel
    property point mapOffset: Qt.point(0, 0)
    property real baseZoomLevel: 15

    // Propriété pour éviter les mises à jour trop fréquentes
    property bool isUpdating: false

    // Connexion avec la carte
    Connections {
        target: mapview

        function onCenterChanged() {
            if (!isUpdating) {
                isUpdating = true;
                updateTimer.restart();
            }
        }

        function onZoomLevelChanged() {
            if (!isUpdating) {
                isUpdating = true;
                radius = Math.max(20, Math.min(60, baseRadius * Math.pow(2, (mapview.zoomLevel - baseZoomLevel) / 3)));
                resetGrid();
                updateTimer.restart();
            }
        }
    }

    // Timer pour éviter les mises à jour trop fréquentes
    Timer {
        id: updateTimer
        interval: 150 // Délai pour regrouper les mises à jour
        running: false
        repeat: false
        onTriggered: {
            updateGridPosition();
            isUpdating = false;
        }
    }

    function isPointInHexagon(px, py, hexX, hexY) {
        let dx = Math.abs(px - hexX)
        let dy = Math.abs(py - hexY)

        let r = radius
        let h = r * Math.sqrt(3) / 2

        return (dx <= r / 2) && (dy <= h) ||
               (dx <= r) && (dy <= h / 2)
    }

    function getHexagonPosition(index) {
        let cols = Math.ceil(hexGrid.width / (radius * 1.5));
        let col = index % cols;
        let row = Math.floor(index / cols);

        return {
            x: col * radius * 1.5,
            y: row * radius * Math.sqrt(3) + (col % 2 === 1 ? radius * Math.sqrt(3) / 2 : 0)
        };
    }

    function updateHexagonWithCar(hexIndex, carId, isInside) {
        if (!hexagonCarCounts[hexIndex]) {
            hexagonCarCounts[hexIndex] = new Set();
        }

        let wasEmpty = hexagonCarCounts[hexIndex].size === 0;

        if (isInside) {
            hexagonCarCounts[hexIndex].add(carId);
        } else {
            hexagonCarCounts[hexIndex].delete(carId);
        }

        let isEmpty = hexagonCarCounts[hexIndex].size === 0;

        if (wasEmpty !== isEmpty) {
            let item = repeater.itemAt(hexIndex);
            if (item) {
                item.children[0].requestPaint();
            }
        }
    }

    function updateGridPosition() {
        let centerPoint = mapview.fromCoordinate(mapview.center);
        mapOffset = Qt.point(
            (hexGrid.width / 2) - centerPoint.x,
            (hexGrid.height / 2) - centerPoint.y
        );

        for (let i = 0; i < repeater.count; i++) {
            let item = repeater.itemAt(i);
            if (item) {
                let pos = getHexagonPosition(i);
                item.x = pos.x + mapOffset.x;
                item.y = pos.y + mapOffset.y;
            }
        }
    }

    function updateHexagonsForCar(carX, carY, carId) {
        if (isUpdating) return;

        let adjustedX = carX - mapOffset.x;
        let adjustedY = carY - mapOffset.y;

        // Optimisation : ne vérifier que les hexagones proches
        let col = Math.floor(adjustedX / (radius * 1.5));
        let row = Math.floor(adjustedY / (radius * Math.sqrt(3)));
        let checkRange = 2;

        for (let r = row - checkRange; r <= row + checkRange; r++) {
            for (let c = col - checkRange; c <= col + checkRange; c++) {
                if (r < 0 || c < 0) continue;

                let index = r * Math.ceil(hexGrid.width / (radius * 1.5)) + c;
                if (index >= repeater.count) continue;

                let item = repeater.itemAt(index);
                if (item) {
                    let hexCenter = Qt.point(
                        item.x + item.width / 2,
                        item.y + item.height / 2
                    );

                    let isInside = isPointInHexagon(carX, carY, hexCenter.x, hexCenter.y);
                    updateHexagonWithCar(index, carId, isInside);
                }
            }
        }
    }

    Repeater {
        id: repeater
        model: Math.ceil(parent.width / (radius * 1.5)) * Math.ceil(parent.height / (radius * Math.sqrt(3)))

        delegate: Item {
            id: hexItem
            width: radius * 2
            height: radius * Math.sqrt(3)

            Canvas {
                id: hexCanvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.save();

                    var centerX = width / 2;
                    var centerY = height / 2;

                    ctx.beginPath();
                    for (var i = 0; i < 6; i++) {
                        var angle = Math.PI / 3 * i;
                        var xPos = centerX + radius * Math.cos(angle);
                        var yPos = centerY + radius * Math.sin(angle);
                        if (i === 0) {
                            ctx.moveTo(xPos, yPos);
                        } else {
                            ctx.lineTo(xPos, yPos);
                        }
                    }
                    ctx.closePath();

                    if (hexagonCarCounts[index] && hexagonCarCounts[index].size > 0) {
                        let intensity = Math.min(hexagonCarCounts[index].size * 0.3, 1.0);
                        ctx.fillStyle = Qt.rgba(1.0, 0, 1.0, intensity);
                        ctx.fill();

                        ctx.fillStyle = "white";
                        ctx.font = Math.floor(radius/3) + "px Arial";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        ctx.fillText(hexagonCarCounts[index].size.toString(), centerX, centerY);
                    }

                    ctx.strokeStyle = "black";
                    ctx.globalAlpha = 0.5;
                    ctx.lineWidth = 1;
                    ctx.stroke();
                    ctx.restore();
                }
            }
        }
    }
    //timer

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!isUpdating) {
                for (let i = 0; i < carItems.length; i++) {
                    let car = carItems[i];
                    if (car && car.coordinate) {
                        let point = mapview.fromCoordinate(car.coordinate, false);
                        updateHexagonsForCar(point.x, point.y, "car_" + i);
                    }
                }
            }
        }
    }

    function resetGrid() {
        hexagonCarCounts = {};
        for (let i = 0; i < repeater.count; i++) {
            let item = repeater.itemAt(i);
            if (item) {
                item.children[0].requestPaint();
            }
        }
    }
}

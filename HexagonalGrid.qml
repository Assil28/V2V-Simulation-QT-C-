import QtQuick 2.15

Item {
    id: hexGrid
    width: 800
    height: 600

    // Propriétés de la grille
    property int radius: 30
    // Maintenant on stocke le nombre de voitures par hexagone
    property var hexagonCarCounts: ({})

    // Fonction pour vérifier si un point est dans un hexagone
    function isPointInHexagon(px, py, hexX, hexY) {
        let dx = Math.abs(px - hexX)
        let dy = Math.abs(py - hexY)

        let r = radius
        let h = r * Math.sqrt(3) / 2

        return (dx <= r / 2) && (dy <= h) ||
               (dx <= r) && (dy <= h / 2)
    }

    // Fonction pour mettre à jour l'état d'un hexagone spécifique
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

        // Si l'état a changé, on demande un nouveau rendu
        if (wasEmpty !== isEmpty) {
            let item = repeater.itemAt(hexIndex);
            if (item) {
                item.children[0].requestPaint();
            }
        }
    }

    // Fonction pour mettre à jour tous les hexagones pour une voiture
    function updateHexagonsForCar(carX, carY, carId) {
        for (let i = 0; i < repeater.count; i++) {
            let item = repeater.itemAt(i);
            if (item) {
                let hexCenter = Qt.point(
                    item.x + item.width / 2,
                    item.y + item.height / 2
                );

                let isInside = isPointInHexagon(carX, carY, hexCenter.x, hexCenter.y);
                updateHexagonWithCar(i, carId, isInside);
            }
        }
    }

    Repeater {
        id: repeater
        model: Math.ceil(hexGrid.width / (radius * 1.5)) * Math.ceil(hexGrid.height / (radius * Math.sqrt(3)))

        delegate: Item {
            id: hexItem
            width: radius * 2
            height: radius * Math.sqrt(3)
            x: (index % Math.ceil(hexGrid.width / (radius * 1.5))) * radius * 1.5
            y: Math.floor(index / Math.ceil(hexGrid.width / (radius * 1.5))) * radius * Math.sqrt(3) +
               ((index % 2 === 1) ? radius * Math.sqrt(3) / 2 : 0)

            Canvas {
                id: hexCanvas
                anchors.fill: parent

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

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

                    // Colorer l'hexagone en fonction du nombre de voitures
                    if (hexagonCarCounts[index] && hexagonCarCounts[index].size > 0) {
                        // Intensité basée sur le nombre de voitures
                        let intensity = Math.min(hexagonCarCounts[index].size * 0.3, 1.0);
                        ctx.fillStyle = Qt.rgba(1.0, 0, 1.0, intensity);
                        ctx.fill();

                        // Afficher le nombre de voitures
                        ctx.fillStyle = "white";
                        ctx.font = "12px Arial";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        ctx.fillText(hexagonCarCounts[index].size.toString(), centerX, centerY);
                    }

                    ctx.strokeStyle = "black";
                    ctx.globalAlpha = 0.5;
                    ctx.stroke();
                }
            }
        }
    }

    // Timer pour la mise à jour périodique
    Timer {
        interval: 100  // Mise à jour toutes les 100ms
        running: true
        repeat: true
        onTriggered: {
            // Pour chaque voiture sur la carte
            for (let i = 0; i < carItems.length; i++) {
                let car = carItems[i];
                if (car && car.coordinate) {
                    // Convertir les coordonnées GPS en coordonnées d'écran
                    let point = mapview.fromCoordinate(car.coordinate, false);
                    updateHexagonsForCar(point.x, point.y, "car_" + i);
                }
            }
        }
    }

    // Fonction pour réinitialiser la grille
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

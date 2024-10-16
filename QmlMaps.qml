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

    // Car animation properties
    property var carPath: []
    property int carPathIndex: 0
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
            z: 1 // Mettre un niveau de z plus bas pour les routes
        }

        // Car item
        MapQuickItem {
            id: carItem
            anchorPoint.x: carImage.width/2
            anchorPoint.y: carImage.height/2
            coordinate: QtPositioning.coordinate(0, 0) // Will be updated in animation


             z: 2

            sourceItem: Image {
                id: carImage
                source: "car.svg"
                width: 32
                height: 32
            }

            // Rotation to make the car face the direction of travel
            rotation: 0 // Will be updated during animation
        }

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

            onDoubleClicked: {
                zoomLevel += 1;
                mapview.zoomLevel = zoomLevel;
            }

            onWheel: function(event) {
                if (event.angleDelta.y > 0) {
                    zoomLevel += 1;
                } else {
                    zoomLevel -= 1;
                }
                mapview.zoomLevel = zoomLevel;
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
            console.log("Marker created at:", lati, longi)
        }
    }

    function drawPathWithCoordinates(coordinates) {
        var transparentPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 10; line.color: "blue"; path: [] }', mapview);
        var borderPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 5; line.color: "white"; path: [] }', mapview);

        for (var i = 0; i < coordinates.length; i++) {
            transparentPolyline.path.push(coordinates[i]);
            borderPolyline.path.push(coordinates[i]);
        }

        mapview.addMapItem(transparentPolyline);
        mapview.addMapItem(borderPolyline);
    }

    function animateCarAlongPath(coordinates) {
        carPath = coordinates;
        carPathIndex = 0;
        carItem.coordinate = carPath[0];
        carAnimation.start();
    }

    Timer {
        id: carAnimation
        interval: 100 // Update every 100ms
        running: false
        repeat: true
        onTriggered: {
            if (carPathIndex < carPath.length - 1) {
                var start = carPath[carPathIndex];
                var end = carPath[carPathIndex + 1];

                var progress = (carAnimation.interval / animationDuration) * carPath.length;
                var interpolatedPosition = QtPositioning.coordinate(
                    start.latitude + (end.latitude - start.latitude) * progress,
                    start.longitude + (end.longitude - start.longitude) * progress
                );

                carItem.coordinate = interpolatedPosition;

               // var angle = Math.atan2(end.longitude - start.longitude, end.latitude - start.latitude) * 180 / Math.PI;
               // carItem.rotation = angle;

                carPathIndex++;
            } else {
                carAnimation.stop();
            }
        }
    }

    Component {
        id: locmaker
        MapQuickItem {
            id: markerImg
            anchorPoint.x: image.width / 2
            anchorPoint.y: image.height
            coordinate: QtPositioning.coordinate(0, 0)
            sourceItem: Image {
                id: image
                width: 20
                height: 20
                source: "https://www.pngarts.com/files/3/Map-Marker-Pin-PNG-Image-Background.png"
            }
        }
    }

    HexagonalGrid {
        anchors.fill: parent
        z: 1
    }
}

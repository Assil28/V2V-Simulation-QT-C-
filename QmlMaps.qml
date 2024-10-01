import QtQuick 2.15
import QtLocation 6.8
import QtPositioning 6.8

Rectangle {
    id: window
    width: 800
    height: 600

    property double latitude: 47.7508
    property double longitude: 7.3359
    property int zoomLevel: 12

    property Component locationmarker: locmaker
    property Component carmarker: carMaker

    property var polylinePoints: []

    Plugin {
        id: googlemapview
        name: "osm"
    }

    Map {
        id: mapview
        anchors.fill: parent
        plugin: googlemapview
        center: QtPositioning.coordinate(latitude, longitude)
        zoomLevel: 15

        MapPolyline {
            id: pathLine
            line.width: 5
            line.color: "blue"
            path: polylinePoints
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
        }
    }

    function setCenterPosition(lati, longi) {
        mapview.pan(latitude - lati, longitude - longi);
        latitude = lati;
        longitude = longi;
    }

    function setLocationMarking(lati, longi) {
        console.log("QML: Setting marker at: ", lati, longi);
        var item = locationmarker.createObject(window, {
            coordinate: QtPositioning.coordinate(lati, longi)
        });
        if (item) {
            mapview.addMapItem(item);
            console.log("QML: Marker created successfully.");
        } else {
            console.log("QML: Failed to create marker.");
        }
    }

    function setCarMarker(lati, longi) {
        console.log("QML: Setting car marker at: ", lati, longi);
        var item = carmarker.createObject(window, {
            coordinate: QtPositioning.coordinate(lati, longi)
        });
        if (item) {
            mapview.addMapItem(item);
            console.log("QML: Car marker created successfully.");
        } else {
            console.log("QML: Failed to create car marker.");
        }
    }

    function drawPathWithCoordinates(pathCoordinates) {
        if (pathCoordinates.length === 0) {
            console.log("No valid path coordinates provided.");
            return;
        }

        pathLine.path = [];

        for (var i = 0; i < pathCoordinates.length; i++) {
            var coord = pathCoordinates[i];
            pathLine.path.push(QtPositioning.coordinate(coord.latitude, coord.longitude));
        }

        console.log("Path drawn with coordinates:", pathLine.path);
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

    Component {
        id: carMaker
        MapQuickItem {
            id: carMarkerImg
            anchorPoint.x: carRect.width / 2
            anchorPoint.y: carRect.height / 2
            coordinate: QtPositioning.coordinate(0, 0)
            sourceItem: Rectangle {
                id: carRect
                width: 30
                height: 30
                color: "red"
                border.color: "black"
                border.width: 2
            }
        }
    }
}

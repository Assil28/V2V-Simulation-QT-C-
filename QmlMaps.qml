import QtQuick 2.15
import QtLocation 6.8
import QtQuick.Controls 2.15
import QtPositioning 6.8

Rectangle {
    id: window
    width: 800
    height: 600

    property double latitude: 47.7508
    property double longitude: 7.3359
    property int zoomLevel: 20 // Set default zoomLevel to 20

    property Component locationmarker: locmaker

    Plugin {
        id: googlemapview
        name: "osm"
    }

    Map {
        id: mapview
        anchors.fill: parent
        plugin: googlemapview
        center: QtPositioning.coordinate(latitude, longitude)
        zoomLevel: 17 // Bind zoomLevel to the Map's zoom level

        MouseArea {
            anchors.fill: parent
            drag.target: mapview
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: {
                // Store the position where the mouse is pressed
                drag.startX = mouse.x;
                drag.startY = mouse.y;
            }

            onReleased: {
                // Stop panning
                mapview.panTo(mapview.center);
            }

            onPositionChanged: {
                if (drag.active) {
                    // Calculate the new center based on mouse drag
                    var deltaLatitude = (mouseY - drag.startY) * 0.0001; // Adjust sensitivity
                    var deltaLongitude = (mouseX - drag.startX) * 0.0001; // Adjust sensitivity
                    mapview.center = QtPositioning.coordinate(latitude + deltaLatitude, longitude - deltaLongitude);
                }
            }

            // Handle double-click for zooming
            onDoubleClicked: {
                zoomLevel += 1; // Zoom in
                mapview.zoomLevel = zoomLevel; // Update the map's zoom level
            }

            // Handle mouse wheel for zooming
            onWheel: function(event) {
                if (event.angleDelta.y > 0) {
                    zoomLevel += 1; // Zoom in
                } else {
                    zoomLevel -= 1; // Zoom out
                }
                mapview.zoomLevel = zoomLevel; // Update the map's zoom level
            }
        }
    }

    function setCenterPosition(lati, longi) {
        mapview.pan(latitude - lati, longitude - longi);
        latitude = lati;
        longitude = longi;
    }

    function setLocationMarking(lati, longi) {
        console.log("Setting marker at: ", lati, longi);
        var item = locationmarker.createObject(window, {
            coordinate: QtPositioning.coordinate(lati, longi)
        });
        if (item) {
            mapview.addMapItem(item);
            console.log("Marker created successfully.");
        } else {
            console.log("Failed to create marker.");
        }
    }

    // Position the marker at the location
    Component {
        id: locmaker
        MapQuickItem {
            id: markerImg
            anchorPoint.x: image.width / 2
            anchorPoint.y: image.height
            coordinate: QtPositioning.coordinate(0, 0) // Initial coordinate; will be overridden
            sourceItem: Image {
                id: image
                width: 20
                height: 20
                source: "https://www.pngarts.com/files/3/Map-Marker-Pin-PNG-Image-Background.png"
            }
        }
    }

    // Ajouter les grilles hexagonales par-dessus la carte
    HexagonalGrid {
        anchors.fill: parent
        z: 1  // Ensure it is above the map
    }
}

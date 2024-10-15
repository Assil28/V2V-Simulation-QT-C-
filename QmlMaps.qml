import QtQuick 2.15
import QtLocation 6.8
import QtPositioning 6.8

Rectangle {
    id: window
    width: 800
    height: 600

    property double latitude: 47.729679
    property double longitude: 7.321515
    property int zoomLevel: 15  // Initial zoom level

    property Component locationmarker: locmaker
    property var polylinePoints: []  // Holds the coordinates for the polyline

    property var polylines: []  // Stocke toutes les polylines

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

        // Polyline to display the path between two points
        MapPolyline {
            id: routeLine
            line.width: 5
            line.color: "red"
            path: window.polylinePoints
        }

        // MouseArea for zooming and panning
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

                    //Handle double-click for zooming
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

    // Center the map
    function setCenterPosition(lati, longi) {
        mapview.center = QtPositioning.coordinate(lati, longi)
    }

    // Add a location marker
    function setLocationMarking(lati, longi) {
        var item = locationmarker.createObject(window, {
            coordinate: QtPositioning.coordinate(lati, longi)
        })
        if (item) {
            mapview.addMapItem(item)
            console.log("Marker created at:", lati, longi)
        }
    }

    // Draw the path using the coordinates from the backend

    function drawPathWithCoordinates(coordinates) {
        // Create the first polyline (thicker and transparent, for the center of the road)
        var transparentPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 10; line.color: "blue"; path: [] }', mapview);

        // Add coordinates to the transparent polyline
        for (var i = 0; i < coordinates.length; i++) {
            transparentPolyline.path.push(coordinates[i]);
        }

        // Add the transparent polyline to the map
        mapview.addMapItem(transparentPolyline);

        // Create the second polyline (thinner and blue, for the borders of the road)
        var borderPolyline = Qt.createQmlObject('import QtLocation 5.0; MapPolyline { line.width: 5; line.color: "white"; path: [] }', mapview);

        // Add coordinates to the blue polyline (borders)
        for (var i = 0; i < coordinates.length; i++) {
            borderPolyline.path.push(coordinates[i]);
        }

        // Add the blue border polyline to the map
        mapview.addMapItem(borderPolyline);
    }




    // Function to set the polyline path between two markers
        // function drawPathBetweenMarkers(pathCoordinates) {
        //     // Assurez-vous que les coordonnées sont valides avant de dessiner
        //     if (pathCoordinates.length === 0) {
        //         console.log("No valid path coordinates provided.");
        //         return;
        //     }

        //     // Effacer les anciens chemins
        //     pathLine.path = []; // Réinitialiser le chemin

        //     // Créer le chemin avec les nouvelles coordonnées
        //     for (var i = 0; i < pathCoordinates.length; i++) {
        //         var coord = pathCoordinates[i];
        //         pathLine.path.push(QtPositioning.coordinate(coord.latitude, coord.longitude));
        //     }

        //     console.log("Path drawn with coordinates:", pathLine.path);
        // }

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

       // Ajouter les grilles hexagonales par-dessus la carte
        HexagonalGrid {
            anchors.fill: parent
            z: 1  // Ensure it is above the map
        }

   }

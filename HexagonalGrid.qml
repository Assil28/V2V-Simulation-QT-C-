import QtQuick 2.15

Item {
    id: hexGrid
    width: 800
    height: 600

    property int radius: 50 // Radius of the hexagons

    // We use a Repeater to generate hexagons
    Repeater {
        model: Math.ceil(hexGrid.width / (radius * 1.5)) * Math.ceil(hexGrid.height / (radius * Math.sqrt(3)))
        delegate: Item {
            width: radius * 2
            height: radius * Math.sqrt(3)
            x: (index % Math.ceil(hexGrid.width / (radius * 1.5))) * radius * 1.5
            y: Math.floor(index / Math.ceil(hexGrid.width / (radius * 1.5))) * radius * Math.sqrt(3) + ((index % 2 === 1) ? radius * Math.sqrt(3) / 2 : 0)

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    var centerX = width / 2;
                    var centerY = height / 2;

                    // Start drawing the hexagon
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
                    ctx.strokeStyle = "black";
                    ctx.globalAlpha = 0.5; // Set opacity for semi-transparent grid
                    ctx.stroke();
                }
            }
        }
    }
}

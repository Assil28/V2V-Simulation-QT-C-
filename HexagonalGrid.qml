import QtQuick 2.15

Item {
    id: hexGrid
    width: 800
    height: 600

    // Définition du rayon des hexagones
    property int radius: 50

    // Utilisation d'un Repeater pour générer des hexagones
    Repeater {
        // Modèle calculé pour déterminer le nombre d'hexagones à dessiner
        model: Math.ceil(hexGrid.width / (radius * 1.5)) * Math.ceil(hexGrid.height / (radius * Math.sqrt(3)))

        // Définition du délégué pour chaque hexagone
        delegate: Item {
            width: radius * 2 // Largeur de l'hexagone (diamètre)
            height: radius * Math.sqrt(3) // Hauteur de l'hexagone
            // Positionnement de l'hexagone dans la grille
            x: (index % Math.ceil(hexGrid.width / (radius * 1.5))) * radius * 1.5 // Position horizontale
            y: Math.floor(index / Math.ceil(hexGrid.width / (radius * 1.5))) * radius * Math.sqrt(3) +
              ((index % 2 === 1) ? radius * Math.sqrt(3) / 2 : 0) // Position verticale, décalage pour les lignes impaires

            // Utilisation d'un Canvas pour dessiner l'hexagone
            Canvas {
                anchors.fill: parent // Le Canvas remplit l'Item parent
                onPaint: {
                    var ctx = getContext("2d"); // Obtention du contexte de dessin en 2D
                    var centerX = width / 2; // Coordonnée X du centre de l'hexagone
                    var centerY = height / 2; // Coordonnée Y du centre de l'hexagone

                    // Début du dessin de l'hexagone
                    ctx.beginPath();
                    for (var i = 0; i < 6; i++) {
                        var angle = Math.PI / 3 * i; // Calcul de l'angle pour chaque sommet
                        var xPos = centerX + radius * Math.cos(angle); // Position X du sommet
                        var yPos = centerY + radius * Math.sin(angle); // Position Y du sommet
                        if (i === 0) {
                            ctx.moveTo(xPos, yPos); // Déplace le curseur au premier sommet
                        } else {
                            ctx.lineTo(xPos, yPos); // Trace la ligne vers les autres sommets
                        }
                    }
                    ctx.closePath(); // Ferme le chemin
                    ctx.strokeStyle = "black"; // Couleur du contour de l'hexagone
                    ctx.globalAlpha = 0.5; // Définit l'opacité pour un fond de grille semi-transparent
                    ctx.stroke(); // Dessine le contour de l'hexagone
                }
            }
        }
    }
}

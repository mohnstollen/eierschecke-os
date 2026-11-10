/* EierscheckeOS – Diashow während der Installation */
import QtQuick 2.15;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 12000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Rectangle { anchors.fill: parent; color: "#1e1e22"; z: -1 }

    component Folie: Slide {
        property string ueberschrift
        property string inhalt
        Image {
            id: logo
            source: "logo.png"
            width: 140; height: 140
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
        }
        Text {
            id: titel
            text: ueberschrift
            color: "#e8b84a"
            font.pixelSize: 26
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 24
        }
        Text {
            text: inhalt
            color: "#d8d4c8"
            font.pixelSize: 15
            wrapMode: Text.WordWrap
            width: Math.min(parent.width - 80, 620)
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.3
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: titel.bottom
            anchors.topMargin: 16
        }
    }

    Folie {
        ueberschrift: "Schicht für Schicht zum Desktop"
        inhalt: "EierscheckeOS wird jetzt eingerichtet. Das dauert nur ein paar Minuten – Zeit für ein Stück Kuchen."
    }
    Folie {
        ueberschrift: "Alles für den Alltag"
        inhalt: "LibreOffice, Firefox, Thunderbird, Signal und viele weitere Programme sind schon dabei. Mehr gibt es über Flatpak und die Paketverwaltung."
    }
    Folie {
        ueberschrift: "Ein Klick, alles aktuell"
        inhalt: "Das Update-Center aktualisiert System, Hersteller-Quellen und Flatpaks in einem Durchgang – und legt vorher automatisch einen Snapshot an."
    }
    Folie {
        ueberschrift: "Sicher zurück"
        inhalt: "Dank Btrfs und Snapper lässt sich ein früherer Stand direkt im Startmenü auswählen, falls ein Update einmal Ärger macht."
    }
    Folie {
        ueberschrift: "Lange Akkulaufzeit"
        inhalt: "TLP ist für das ThinkPad X280 voreingestellt und schont den Akku mit Ladeschwellen von 75 und 80 Prozent."
    }
    Folie {
        ueberschrift: "Zum Basteln gemacht"
        inhalt: "VSCodium, Geany, Thonny für MicroPython und OrcaSlicer für den 3D-Druck sind startklar."
    }

    function onActivate() { presentation.currentSlide = 0; }
    function onLeave() { }
}

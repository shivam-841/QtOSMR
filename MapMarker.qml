import QtQuick 2.15
import QtLocation 5.15
import QtPositioning 5.15

MapQuickItem {
    id: marker
    anchorPoint.x: icon.width / 2
    anchorPoint.y: icon.height
    coordinate: QtPositioning.coordinate(0, 0)

    property string iconSource : "qrc:/C:/Users/shiva/Downloads/Green_marker.png"

    sourceItem: Image {
        id: icon
        source: iconSource // or use a local image
        width: 32
        height: 32
    }
}

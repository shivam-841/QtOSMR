import QtQuick 2.15
import QtQuick.Controls 2.15
import QtLocation 5.15
import QtPositioning 5.15

Item {
    width: 800
    height: 600
    property bool sidebarVisible: false

    Plugin {
        id: mapPlugin
        name: "osm"

        PluginParameter {
            name: "osm.mapping.providers"
            value: "osm"
        }

        PluginParameter {
            name: "osm.mapping.tileserver.baseurl"
            value: "https://a.tile.openstreetmap.org/"
        }

        PluginParameter {
            name: "osm.useragent"
            value: "OSRMDesktopApp/1.0"
        }

        PluginParameter {
            name: "osm.mapping.cache.directory"
            value: "./mapcache"
        }
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(28.6139, 77.2090)
        zoomLevel: 14

        property var markers: []
        property var startCoord: null
        property var endCoord: null
        property var routeLine: null

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton

            property real lastX: 0
            property real lastY: 0

            onClicked: (mouse) => {
                var coord = map.toCoordinate(Qt.point(mouse.x, mouse.y))
                console.log("Clicked at:", coord.latitude, coord.longitude)

                var markerComponent = Qt.createComponent("MapMarker.qml")

                if (map.startCoord === null) {
                    // First click – start (green)
                    map.startCoord = coord

                    startTextField.text = coord.latitude.toFixed(5) + ", " + coord.longitude.toFixed(5)

                    if (markerComponent.status === Component.Ready) {
                        var marker = markerComponent.createObject(map, {
                            coordinate: coord,
                            iconSource: "qrc:/C:/Users/shiva/Downloads/Green_marker.png"
                        })
                        map.addMapItem(marker)
                        map.markers.push(marker)
                    }
                } else {
                    // Remove previous red marker (if any)
                    if (map.markers.length > 1) {
                        map.removeMapItem(map.markers[1])
                        map.markers.pop()
                    }

                    map.endCoord = coord

                    endTextField.text = coord.latitude.toFixed(5) + ", " + coord.longitude.toFixed(5)

                    if (markerComponent.status === Component.Ready) {
                        var marker = markerComponent.createObject(map, {
                            coordinate: coord,
                            iconSource: "qrc:/C:/Users/shiva/Downloads/Red_marker.png"
                        })
                        map.addMapItem(marker)
                        map.markers.push(marker)
                    }

                    map.requestRoute()
                }
            }

            onPressed: (mouse) => {
                lastX = mouse.x
                lastY = mouse.y
            }

            onPositionChanged: (mouse) => {
                var dx = mouse.x - lastX
                var dy = mouse.y - lastY
                lastX = mouse.x
                lastY = mouse.y
                map.pan(-dx, -dy)
            }

            onWheel: (wheel) => {
                map.zoomLevel += wheel.angleDelta.y > 0 ? 0.5 : -0.5
            }
        }

        function requestRoute() {
            if (map.startCoord === null || map.endCoord === null)
                return

            var mode = travelModeComboBox.currentText
            // 🔧 Added steps=true to get directions
            var url = `https://router.project-osrm.org/route/v1/${mode}/${map.startCoord.longitude},${map.startCoord.latitude};${map.endCoord.longitude},${map.endCoord.latitude}?overview=full&geometries=geojson&steps=true`

            var xhr = new XMLHttpRequest()
            xhr.open("GET", url)
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText)
                    map.drawRoute(response.routes[0].geometry.coordinates)

                    var route = response.routes[0]
                    var legs = route.legs[0]

                    distanceText.text = "Distance: " + (route.distance / 1000).toFixed(2) + " km"
                    durationText.text = "Duration: " + (route.duration / 60).toFixed(1) + " mins"

                    // // 🧹 Clear previous directions (safe way)
                    // while (directionList.children.length > 0) {
                    //     directionList.children[0].destroy()
                    // }

                    // // 📝 Create direction items
                    // for (var i = 0; i < legs.steps.length; i++) {
                    //     var step = legs.steps[i]
                    //     var instruction = step.maneuver.instruction || step.name || "Continue"

                    //     var directionText = Qt.createQmlObject(`
                    //         import QtQuick 2.15
                    //         Text {
                    //             wrapMode: Text.WordWrap
                    //             font.pointSize: 10
                    //             text: "${i + 1}. ${instruction}"
                    //         }
                    //     `, directionList)
                    // }

                    sidebarVisible = true
                }
            }

            xhr.send()
        }


        function drawRoute(coords) {
            var routePath = []

            for (var i = 0; i < coords.length; i++) {
                routePath.push(QtPositioning.coordinate(coords[i][1], coords[i][0]))
            }

            if (map.routeLine !== null) {
                map.removeMapItem(map.routeLine)
            }

            // Set route color based on the selected travel mode
            var routeColor = "#87CEFA" // Default: Light Blue for Car

            // Change color based on mode
            if (travelModeComboBox.currentText === "bike") {
                routeColor = "#FF8C00" // Dark Orange for Bike
            } else if (travelModeComboBox.currentText === "foot") {
                routeColor = "#32CD32" // Lime Green for Foot
            }

            // Create the route line with dynamic color
            map.routeLine = Qt.createQmlObject(`
                import QtPositioning 5.15
                import QtLocation 5.15

                MapPolyline {
                    line.width: 4
                    line.color: "${routeColor}"
                    path: []
                }
            `, map)

            map.routeLine.path = routePath
            map.addMapItem(map.routeLine)
        }

        function clearMarkers() {
            for (var i = 0; i < markers.length; i++) {
                map.removeMapItem(markers[i])
            }
            markers = []
        }

        function clearRoute() {
            if (routeLine !== null) {
                map.removeMapItem(routeLine)
                routeLine = null
            }
        }
    }

    Column {
        id: inputBoxColumn
        spacing: 0
        anchors {
            top: parent.top
            left: parent.left
        }

        // 🟢 Start Input Box
        Rectangle {
            width: 300
            height: 40
            color: "white"
            radius: 4
            border.color: "#cccccc"

            Row {
                anchors.fill: parent
                spacing: 0

                // Left border strip
                Rectangle {
                    width: 4
                    height: parent.height
                    color: "green"
                }

                // Small spacing between border and TextField
                Item { width: 8 }

                // Text Field
                TextField {
                    id: startTextField
                    placeholderText: "Start - press enter to drop marker"
                    selectByMouse: true
                    readOnly: true
                    font.pointSize: 12
                    leftPadding: 0
                    background: Rectangle {
                        color: "white"
                        border.width: 0
                        radius: 4
                    }
                }

                // Large spacing between TextField and Button
                Item { width: 20 }

                // Zoom In Button (+)
                Rectangle {
                    width: 40
                    height: 40
                    radius: 6
                    border.color: "#00688B"
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.bold: true
                        font.pointSize: 18
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: map.zoomLevel += 1
                    }
                }
            }
        }

        // 🔴 End Input Box
        Rectangle {
            width: 300
            height: 40
            color: "white"
            radius: 4
            border.color: "#cccccc"

            Row {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    width: 4
                    height: parent.height
                    color: "red"
                }

                // Small spacing
                Item { width: 8 }

                TextField {
                    id: endTextField
                    placeholderText: "End - press enter to drop marker"
                    selectByMouse: true
                    readOnly: true
                    font.pointSize: 12
                    rightPadding: 12
                    background: Rectangle {
                        color: "white"
                        border.width: 0
                        radius: 4
                    }
                }

                // Large spacing
                Item { width: 20 }

                // Zoom Out Button (-)
                Rectangle {
                    width: 40
                    height: 40
                    radius: 6
                    border.color: "#00688B"
                    Text {
                        anchors.centerIn: parent
                        text: "-"
                        font.bold: true
                        font.pointSize: 18
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: map.zoomLevel -= 1
                    }
                }
            }
        }

        // Travel Mode Selector
        Row {
            spacing: 20
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.leftMargin: 10

            // 🧭 Travel Mode ComboBox
            ComboBox {
                id: travelModeComboBox
                height: 30
                width: 120
                model: ["car", "bike", "foot"]
                currentIndex: 0

                onCurrentIndexChanged: {
                    if (map.startCoord !== null && map.endCoord !== null) {
                        map.requestRoute()
                    }
                }
            }

            // 🔁 Interchange Button
            Rectangle {
                width: 100
                height: 30
                radius: 6
                color: "#f0f0f0"
                border.color: "#00688B"

                Text {
                    anchors.centerIn: parent
                    text: "Interchange"
                    font.pointSize: 10
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (map.startCoord && map.endCoord) {
                            // Swap coordinates
                            var temp = map.startCoord
                            map.startCoord = map.endCoord
                            map.endCoord = temp

                            // Update UI
                            var tempText = startTextField.text
                            startTextField.text = endTextField.text
                            endTextField.text = tempText

                            if (map.markers.length === 2) {
                                var startMarker = map.markers[0]
                                var endMarker = map.markers[1]

                                // Swap icon sources
                                var tempIcon = startMarker.iconSource
                                startMarker.iconSource = endMarker.iconSource
                                endMarker.iconSource = tempIcon
                            }

                            map.requestRoute()
                        }
                    }
                }
            }

            // 🔄 Reset Button
            Rectangle {
                width: 100
                height: 30
                radius: 6
                color: "#f0f0f0"
                border.color: "#cc0000"

                Text {
                    anchors.centerIn: parent
                    text: "Reset"
                    font.pointSize: 10
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        map.startCoord = null
                        map.endCoord = null

                        // Clear visual markers (you need to implement these)
                        map.clearMarkers?.()
                        map.clearRoute?.()

                        // Clear text fields
                        startTextField.text = ""
                        endTextField.text = ""
                    }
                }
            }
        }
    }

    Rectangle {
        id: toggleButton
        width: 30
        height: 60
        color: "#dddddd"
        anchors.right: sidebar.left
        anchors.top: parent.top
        z: 3
        radius: 6
        border.color: "#aaaaaa"

        Text {
            anchors.centerIn: parent
            text: sidebarVisible ? "<<" : ">>"
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: sidebarVisible = !sidebarVisible
        }
    }


    // Right Sidebar
    Rectangle {
        id: sidebar
        width: sidebarVisible ? 250 : 0
        height: parent.height
        color: "#ffffff"
        anchors.right: parent.right
        z: 2
        border.color: "#cccccc"
        Behavior on width { NumberAnimation { duration: 250 } }

        Column {
            id: sidebarContent
            visible: sidebarVisible
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: "Route Info"
                font.bold: true
                font.pointSize: 14
            }

            Text {
                id: distanceText
                text: "Distance: --"
                wrapMode: Text.WordWrap
            }

            Text {
                id: durationText
                text: "Duration: --"
                wrapMode: Text.WordWrap
            }

            // Text {
            //     text: "Directions:"
            //     font.bold: true
            // }

            ScrollView {
                width: parent.width
                height: parent.height - 120

                Column {
                    id: directionList
                    spacing: 5
                }
            }
        }
    }
}

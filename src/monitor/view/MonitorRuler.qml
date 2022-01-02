/*
    SPDX-FileCopyrightText: 2017 Jean-Baptiste Mardelle <jb@kdenlive.org>
    SPDX-License-Identifier: GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick.Controls 2.4
import Kdenlive.Controls 1.0
import QtQuick 2.11
import org.kde.kdenlive 1.0 as Kdenlive

    // Monitor ruler
Rectangle {
    id: ruler
    color: activePalette.base
    property bool containsMouse: rulerMouseArea.containsMouse
    property bool seekingFinished : controller.seekFinished
    // The width of the visible part
    property double rulerZoomWidth: root.zoomFactor * width
    // The pixel offset
    property double rulerZoomOffset: root.zoomStart * width / root.zoomFactor
    
    property int playheadPosition: controller.position
    Rectangle {
        color: activePalette.light
        width: parent.width
        height: 1
    }
    
    Timer {
        id: scrollTimer
        interval: 200; running: false;
        onTriggered: {
            if (rulerMouseArea.pressed) {
                // Check if seeking ruler
                var pos = Math.max(rulerMouseArea.mouseX, 0)
                root.mouseRulerPos = pos
                controller.position = Math.min((pos + ruler.rulerZoomOffset) / root.timeScale, root.duration);
            } else if (root.showAudiothumb) {
                // Check if seeking audio thumbnail zone
                root.updateScrolling()
            }
        }
    }
    
    onPlayheadPositionChanged: {
        if (root.zoomFactor == 1) {
            return
        }
        var scaledPosition = ruler.playheadPosition * root.timeScale - ruler.rulerZoomOffset
        if (scaledPosition < root.baseUnit) {
            if (scaledPosition < 0) {
                root.zoomStart = Math.max(0, (rulerZoomOffset + scaledPosition) * root.zoomFactor - (rulerZoomWidth / 2)) / ruler.width
            } else {
                root.zoomStart = Math.max(0, (rulerZoomOffset - root.baseUnit) * root.zoomFactor) / ruler.width
                scrollTimer.start()
            }
        } else if (scaledPosition > ruler.width - root.baseUnit) {
            if (scaledPosition > ruler.width) {
                root.zoomStart = Math.min(ruler.width - rulerZoomWidth, (rulerZoomOffset + scaledPosition) * root.zoomFactor - (rulerZoomWidth / 2)) / ruler.width
            } else {
                root.zoomStart = Math.min(ruler.width - rulerZoomWidth, (rulerZoomOffset + root.baseUnit) * root.zoomFactor) / ruler.width
                scrollTimer.start()
            }
        }
    }

    function zoomInRuler(xPos)
    {
        root.showZoomBar = true
        var currentX = playhead.x
        var currentCursor = playhead.x + playhead.width / 2 + ruler.rulerZoomOffset
        
        // Adjust zoom factor
        root.zoomFactor = Math.min(1, root.zoomFactor / 1.2)
        if (root.zoomFactor * ruler.width < root.baseUnit / 2) {
            // Don't allow too large zoom
            root.zoomFactor = root.baseUnit / 2 / ruler.width
        }
        // Always try to have cursor pos centered in zoom
        var cursorPos = Math.max(0, controller.position / root.duration - root.zoomFactor / 2)
        if (cursorPos + root.zoomFactor > 1) {
            cursorPos = 1 - root.zoomFactor
        }
        root.zoomStart = cursorPos
    }
    
    function zoomOutRuler(xPos)
    {
        root.zoomFactor = Math.min(1, root.zoomFactor * 1.2)
        if (root.zoomFactor == 1) {
            root.zoomStart = 0
            root.showZoomBar = false
        } else {
            // Always try to have cursor pos centered in zoom
            var cursorPos = Math.max(0, controller.position / root.duration - root.zoomFactor / 2)
            if (cursorPos + root.zoomFactor > 1) {
                cursorPos = 1 - root.zoomFactor
            }
            root.zoomStart = cursorPos
        }
    }

    // Zoom bar container
    Kdenlive.ZoomBar {
        id: horZoomBar
        visible: root.showZoomBar
        onVisibleChanged: {
            root.zoomOffset = visible ? height : 0
        }
        toolTipText: controller.toTimecode((root.duration + 1 )* root.zoomFactor)
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.top
        }
        height: root.baseUnit
        fitsZoom: root.zoomFactor === 1 && root.zoomStart === 0
        zoomFactor: root.zoomFactor
        onProposeZoomFactor: root.zoomFactor = proposedValue
        contentPos: root.zoomStart
        onProposeContentPos: root.zoomStart = proposedValue
        onZoomByWheel: {
            if (wheel.angleDelta.y < 0) {
                // zoom out
                zoomOutRuler(wheel.x)
            } else {
                // zoom in
                zoomInRuler(wheel.x)
            }
        }
        onFitZoom: {
            root.zoomFactor = 1
            root.zoomStart = 0
        }
    }

    onSeekingFinishedChanged : {
        playhead.opacity = seekingFinished ? 1 : 0.5
    }

    onRulerZoomWidthChanged: {
        updateRuler()
    }

    Timer {
        id: zoneToolTipTimer
        interval: 3000; running: false;
    }
    function forceRepaint()
    {
        ruler.color = activePalette.base
        // Enforce repaint
        rulerTicks.model = 0
        rulerTicks.model = ruler.rulerZoomWidth / frameSize + 2
        playhead.fillColor = activePalette.windowText
    }

    function updateRuler()
    {
        var projectFps = controller.fps()
        root.timeScale = ruler.width / root.duration / root.zoomFactor
        var displayedLength = root.duration * root.zoomFactor / projectFps;
        if (displayedLength < 3 ) {
            // 1 frame tick
            root.frameSize = root.timeScale
        } else if (displayedLength < 30) {
            // 1 second tick
            frameSize = projectFps * root.timeScale
        } else if (displayedLength < 150) {
            // 5 second tick
            frameSize = 5 * projectFps * root.timeScale
        } else if (displayedLength < 300) {
            // 10 second tick
            frameSize = 10 * projectFps * root.timeScale
        } else if (displayedLength < 900) {
            // 30 second tick
            frameSize = 30 * projectFps * root.timeScale
        } else if (displayedLength < 1800) {
            // 1 min. tick
            frameSize = 60 * projectFps * root.timeScale
        } else if (displayedLength < 9000) {
            // 5 min tick
            frameSize = 300 * projectFps * root.timeScale
        } else if (displayedLength < 18000) {
            // 10 min tick
            frameSize = 600 * projectFps * root.timeScale
        } else {
            // 30 min tick
            frameSize = 18000 * projectFps * root.timeScale
        }
    }

    // Ruler zone
    Rectangle {
        id: zone
        visible: controller.zoneOut > controller.zoneIn
        color: activePalette.highlight
        x: controller.zoneIn * root.timeScale - ruler.rulerZoomOffset
        width: (controller.zoneOut - controller.zoneIn) * root.timeScale
        anchors.bottom: parent.bottom
        height: ruler.height / 2
        opacity: 0.8
        onXChanged: zoneToolTipTimer.start()
        onWidthChanged: zoneToolTipTimer.start()
    }

    // frame ticks
    Repeater {
        id: rulerTicks
        model: ruler.width / frameSize + 2
        Rectangle {
            x: index * frameSize - (ruler.rulerZoomOffset % frameSize)
            anchors.bottom: ruler.bottom
            height: (index % 5) ? ruler.height / 4 : ruler.height / 2
            width: 1
            color: activePalette.windowText
            opacity: 0.5
        }
    }
    MouseArea {
        id: rulerMouseArea
        anchors.fill: parent
        propagateComposedEvents: true
        hoverEnabled: true
        onPressed: {
            if (mouse.buttons === Qt.LeftButton) {
                var pos = Math.max(mouseX, 0)
                controller.position = Math.min((pos + ruler.rulerZoomOffset) / root.timeScale, root.duration);
            }
        }
        onPositionChanged: {
            if (mouse.buttons === Qt.LeftButton) {
                var pos = Math.max(mouseX, 0)
                root.mouseRulerPos = pos
                if (pressed) {
                    controller.position = Math.min((pos + ruler.rulerZoomOffset) / root.timeScale, root.duration);
                }
            }
        }
        onWheel: {
            if (wheel.modifiers & Qt.ControlModifier) {
                if (wheel.angleDelta.y < 0) {
                    // zoom out
                    zoomOutRuler(wheel.x)
                } else {
                    // zoom in
                    zoomInRuler(wheel.x)
                }
            } else {
                wheel.accepted = false
            }
        }
        onEntered: {
            controller.setWidgetKeyBinding(xi18nc("@info:whatsthis", "<shortcut>Wheel</shortcut> or <shortcut>arrows</shortcut> to seek 1 frame, <shortcut>Shift</shortcut> to seek 1 second, <shortcut>Alt</shortcut> to seek to marker, <shortcut>Home</shortcut> / <shortcut>End</shortcut> to go to first / last frame"));
        }
        onExited: {
            controller.setWidgetKeyBinding();
        }
    }
    // Zone duration indicator
    Rectangle {
        visible: inZoneMarker.visible || zoneToolTipTimer.running
        width: inLabel.contentWidth + 4
        height: inLabel.contentHeight + 2
        property int centerPos: zone.x + zone.width / 2 - inLabel.contentWidth / 2
        x: centerPos < 0 ? 0 : centerPos > ruler.width - inLabel.contentWidth ? ruler.width - inLabel.contentWidth - 2 : centerPos
        color: activePalette.alternateBase
        anchors.bottom: ruler.top
        Label {
            id: inLabel
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            text: trimInMouseArea.containsMouse || trimInMouseArea.pressed ? controller.toTimecode(controller.zoneIn) + '>' + controller.toTimecode(controller.zoneOut - controller.zoneIn) : trimOutMouseArea.containsMouse || trimOutMouseArea.pressed ? controller.toTimecode(controller.zoneOut - controller.zoneIn) + '<' + controller.toTimecode(controller.zoneOut) : controller.toTimecode(controller.zoneOut - controller.zoneIn)
            font: fixedFont
            color: activePalette.text
        }
    }
    // monitor zone
    Rectangle {
        id: inZoneMarker
        x: controller.zoneIn * root.timeScale/ root.zoomFactor - ruler.rulerZoomOffset
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        width: 1
        color: activePalette.highlight
        visible: controller.zoneOut > controller.zoneIn && (rulerMouseArea.containsMouse || trimOutMouseArea.containsMouse || trimOutMouseArea.pressed || trimInMouseArea.containsMouse)
    }
    Rectangle {
        x: controller.zoneOut * root.timeScale/ root.zoomFactor - ruler.rulerZoomOffset
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        width: 1
        color: activePalette.highlight
        visible: inZoneMarker.visible
    }
    TimelinePlayhead {
        id: playhead
        visible: controller.position > -1
        height: ruler.height * 0.5
        width: ruler.height * 1
        opacity: 1
        anchors.top: ruler.top
        fillColor: activePalette.windowText
        x: controller.position * root.timeScale - ruler.rulerZoomOffset - (width / 2)
    }
    Rectangle {
        id: trimIn
        x: zone.x - root.baseUnit / 3
        y: zone.y
        height: zone.height
        width: root.baseUnit * .8
        color: 'lawngreen'
        opacity: trimInMouseArea.containsMouse || trimInMouseArea.drag.active ? 0.5 : 0
        Drag.active: trimInMouseArea.drag.active
        Drag.proposedAction: Qt.MoveAction
        MouseArea {
            id: trimInMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            drag.target: parent
            drag.axis: Drag.XAxis
            drag.smoothed: false
            drag.minimumX: 0
            drag.maximumX: ruler.width
            onPressed: {
                controller.startZoneMove()
            }
            onReleased: {
                controller.endZoneMove()
            }
            onPositionChanged: {
                if (mouse.buttons === Qt.LeftButton) {
                    controller.zoneIn = Math.round((trimIn.x + ruler.rulerZoomOffset) / root.timeScale)
                }
            }
        }
    }
    Rectangle {
        id: trimOut
        width: root.baseUnit * .8
        x: zone.x + zone.width - (width * .7)
        y: zone.y
        height: zone.height
        color: 'darkred'
        opacity: trimOutMouseArea.containsMouse || trimOutMouseArea.drag.active ? 0.5 : 0
        Drag.active: trimOutMouseArea.drag.active
        Drag.proposedAction: Qt.MoveAction
        MouseArea {
            id: trimOutMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            drag.target: parent
            drag.axis: Drag.XAxis
            drag.smoothed: false
            drag.minimumX: 0
            drag.maximumX: ruler.width - trimOut.width
            onPressed: {
                controller.startZoneMove()
            }
            onReleased: {
                controller.endZoneMove()
            }
            onPositionChanged: {
                if (mouse.buttons === Qt.LeftButton) {
                    controller.zoneOut = Math.round((trimOut.x + trimOut.width + ruler.rulerZoomOffset) / root.timeScale)
                }
            }
        }
    }

    // markers
    Repeater {
        model: markersModel
        delegate:
        Item {
            anchors.fill: parent
            Rectangle {
                id: markerBase
                width: 1
                height: parent.height
                x: (model.frame) * root.timeScale - ruler.rulerZoomOffset;
                color: model.color
            }
            Rectangle {
                id: markerTooltip
                visible: !rulerMouseArea.pressed && (guideArea.containsMouse || (rulerMouseArea.containsMouse && Math.abs(rulerMouseArea.mouseX - markerBase.x) < 4))
                property int guidePos: markerBase.x - mlabel.contentWidth / 2
                x: guidePos < 0 ? 0 : (guidePos > (parent.width - mlabel.contentWidth) ? parent.width - mlabel.contentWidth : guidePos)
                radius: 2
                width: Math.max(mlabel.contentWidth, imageTooltip.width + 2)
                height: mlabel.contentHeight + imageTooltip.height
                anchors {
                    bottom: parent.top
                }
                color: model.color
                Image {
                    id: imageTooltip
                    visible: markerTooltip.visible && root.baseThumbPath != undefined
                    source: visible ? root.baseThumbPath + model.frame : ''
                    asynchronous: true
                    height: visible ? 4 * mlabel.height : 0
                    fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: markerTooltip.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 1
                }
                Text {
                    id: mlabel
                    text: model.comment
                    font: fixedFont
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    color: '#000'
                }
                MouseArea {
                    z: 10
                    id: guideArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    //onDoubleClicked: timeline.editMarker(clipRoot.binId, model.frame)
                    onClicked: {
                        controller.position = model.frame
                    }
                }
            }
        }
    }
}


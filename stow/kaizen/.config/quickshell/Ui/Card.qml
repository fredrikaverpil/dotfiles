import QtQuick
import QtQuick.Effects

// Raised surface: top-lit gradient, a sheen along the top edge and a drop
// shadow.
Rectangle {
  id: card

  required property var palette // qmllint disable property-override
  property color topColor: palette.cardTop
  property color bottomColor: palette.cardBottom
  property bool shadow: true

  border.color: palette.dim
  border.width: 1
  gradient: Gradient {
    GradientStop { position: 0; color: card.topColor }
    GradientStop { position: 1; color: card.bottomColor }
  }

  layer.enabled: shadow
  layer.effect: MultiEffect {
    shadowEnabled: true
    shadowColor: card.palette.shadow
    shadowBlur: 0.7
    shadowVerticalOffset: 3
  }

  Rectangle {
    anchors.top: parent.top
    anchors.topMargin: 1
    anchors.left: parent.left
    anchors.leftMargin: card.radius * 0.6
    anchors.right: parent.right
    anchors.rightMargin: card.radius * 0.6
    height: 1
    color: card.palette.sheen
  }
}

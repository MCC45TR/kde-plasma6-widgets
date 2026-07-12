import QtQuick
import org.kde.plasma.extras as PlasmaExtras

// Native QMenu-backed context menu.
//
// Unlike PlasmaComponents.Menu (a Qt Quick popup drawn with the Plasma SVG
// theme), PlasmaExtras.Menu is backed by a real QMenu.  It therefore follows
// the desktop widget style, compact menu metrics, rounded translucent surface,
// and KWin's menu blur policy.
PlasmaExtras.Menu {
    id: root

    // Keep the old Menu API available to delegates that use this state to keep
    // the item under the context menu highlighted.
    readonly property bool visible: status !== PlasmaExtras.Menu.Closed

    // Open at the exact pointer position. QMenuProxy interprets x/y relative to
    // visualParent, so callers must pass the MouseArea that received the click.
    function popup(visualItem, x, y) {
        if (!visualItem) {
            return
        }

        root.visualParent = visualItem
        root.open(Math.round(x), Math.round(y))
    }
}

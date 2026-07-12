import org.kde.plasma.extras as PlasmaExtras

// Small compatibility wrapper: callers can keep the familiar onTriggered API
// while the backing implementation remains a native QMenu action.
PlasmaExtras.MenuItem {
    signal triggered()

    onClicked: triggered()
}

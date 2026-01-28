import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker
import "components" as Components

Item {
    id: fullRoot

    // Widget Dimensions
    width: Kirigami.Units.gridUnit * 26
    height: Kirigami.Units.gridUnit * 34

    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20

    // Properties
    readonly property int iconSize: Kirigami.Units.iconSizes.huge
    readonly property int smallIconSize: Kirigami.Units.iconSizes.medium

    // Kicker Models
    Kicker.RootModel {
        id: rootModel
        autoPopulate: true
        appNameFormat: Plasmoid.configuration.appNameFormat || 0
        flat: false 
        sorted: true
        showSeparators: true
        showTopLevelItems: true
        showAllApps: true
    }

    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: fullRoot
        mergeResults: true
    }

    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. Pinned Apps Section (Top)
        Components.PinnedView {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? implicitHeight : 0
            // logic to be added
        }

        // 2. Main Content (SwipeView for Categories)
        SwipeView {
            id: mainSwipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            currentIndex: bottomPanel.currentIndex

            onCurrentIndexChanged: {
                if (bottomPanel.currentIndex !== currentIndex) {
                    bottomPanel.currentIndex = currentIndex
                }
            }

            // Tab 0: App Library (Categorized View)
            Components.AppLibraryView {
                rootModel: rootModel
                onRequestCategoryPage: (index) => {
                     // Offset by 2 (0=Library, 1=Uncategorized, 2+=Categories)
                     mainSwipeView.currentIndex = index + 1 
                }
            }
            
            // Tab 1: Uncategorized Apps
            Components.UncategorizedView {
                id: uncategorizedView
                
                Component.onCompleted: {
                    // Try to find "Lost & Found" or "Uncategorized" in rootModel
                    // Since models are async, this might need a connection or checking later
                    // But usually rootModel is fast.
                    // We iterate over rows.
                    for (let i = 0; i < rootModel.count; i++) {
                        let display = rootModel.data(rootModel.index(i, 0), Qt.DisplayRole)
                        // This comparison is localized, which is bad practice but we lack ID role access easily here.
                        // Common names: "Lost & Found", "Uncategorized", "Kayıp ve Bulunan"
                        // Or we can check if it's the last one?
                        if (display === i18n("Lost & Found") || display === "Lost & Found" || display === "Uncategorized") {
                            uncategorizedView.categoryModel = rootModel.modelForRow(i)
                            break;
                        }
                    }
                }
            }
            
            // Dynamic Categories
            Repeater {
                id: categoriesRepeater
                model: rootModel
                delegate: Components.CategoryPage {
                    categoryModel: rootModel.modelForRow(index)
                }
            }
        }

        // 3. Bottom Panel (Tabs + Power)
        Components.BottomPanel {
            id: bottomPanel
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            
            rootModel: rootModel
            currentIndex: mainSwipeView.currentIndex
            onTabSelected: (index) => {
                mainSwipeView.currentIndex = index
            }
        }
    }
}

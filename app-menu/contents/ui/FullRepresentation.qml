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

    Kicker.RootModel {
        id: allAppsModel
        autoPopulate: true
        appNameFormat: Plasmoid.configuration.appNameFormat || 0
        flat: true // Flattened list for "All Apps"
        sorted: true
        showSeparators: false
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
                     // Offset by 2 (0=Library, 1=AllApps, 2+=Categories)
                     mainSwipeView.currentIndex = index + 2
                }
            }
            
            // Tab 1: All Apps View
            Components.AllAppsView {
                id: allAppsView
                model: allAppsModel
            }
            
            // Dynamic Categories
            Repeater {
                id: categoriesRepeater
                model: rootModel
                delegate: Components.CategoryPage {
                    categoryModel: rootModel.modelForRow(index)
                    
                    // Match visibility with BottomPanel logic
                    property bool isRecent: {
                        const name = model.display;
                         return name === i18n("Recent Applications") || 
                                name === i18n("Recent Files") || 
                                name === i18n("Recent Documents") ||
                                name === "Son Kullanılan Uygulamalar" ||
                                name === "Son Dosyalar";
                    }
                    
                    // If hidden, it shouldn't take up space in SwipeView navigation ideally,
                    // but SwipeView is index-based.
                    // We just hide the content. Swiping to it might show a blank page, 
                    // but since BottomPanel hides the button, user won't click to it.
                    // If user swipes, they will see blank recent pages.
                    // To truly skip, we'd need a filtered model. 
                    // For now, visibility handling in BottomPanel prevents direct access.
                    // Visually, we can just disable it.
                    visible: !isRecent
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

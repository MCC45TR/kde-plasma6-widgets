# KDE Plasma Widget Configuration Guide

## Introduction
Every widget by default has a configure action when you right-click the widget called "MyWidget Settings...". This documentation explains how to create custom configuration pages.

## File Structure
To add custom configuration, you need a `contents/config` folder and specific files:

- `contents/config/main.xml`: Defines the schema (keys, types, default values).
- `contents/config/config.qml`: Defines the tabs in the configuration window.
- `contents/ui/config/ConfigGeneral.qml`: The actual UI for the settings (one file per tab).

## 1. contents/config/main.xml
This file defines the variables that satisfy `plasmoid.configuration.variableName`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
      http://www.kde.org/standards/kcfg/1.0/kcfg.xsd" >
  <kcfgfile name=""/>

  <group name="General">
    <entry name="apiKey" type="String">
      <default></default>
      <label>API Key</label>
    </entry>
    <entry name="updateInterval" type="Int">
      <default>30</default>
      <label>Update Interval</label>
    </entry>
  </group>
</kcfg>
```

**Common/Supported Types:**
- `String`
- `Int`
- `Double`
- `Bool`
- `Color` (Stored as hex string)
- `StringList`
- `Path` (Specially treated for file paths)

## 2. contents/config/config.qml
Defines the tabs in the settings window.

```qml
import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml" // Relative to contents/ui/config/
    }
}
```

## 3. contents/ui/config/ConfigGeneral.qml (The UI)
This file must be an `Item` that defines properties prefixed with `cfg_` matching the names in `main.xml`.

**Crucial Logic:**
When the settings window opens, Plasma looks for properties named `cfg_yourVariableName` in the root Item of this file. 
- It sets `cfg_variable` to the current value from the config.
- When the user clicks "Apply" or "OK", it reads `cfg_variable` and saves it back to the config.

**Using Aliases:**
The easiest way is to alias the `cfg_` property to a control's property.

```qml
import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

Item {
    id: page
    
    // MAPPING
    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_updateInterval: intervalSpin.value
    
    ColumnLayout {
        TextField {
            id: apiKeyField
        }
        
        SpinBox {
            id: intervalSpin
        }
    }
}
```

**Custom Mapping (e.g., ComboBox with String values):**
If you need to map a ComboBox (index) to a String configuration value:

```qml
Item {
    id: page
    
    // 1. Define the property explicitly (not an alias)
    property string cfg_weatherProvider
    
    // 2. Map Config -> UI (When window opens)
    onCfg_weatherProviderChanged: {
        // Find index of string
        var idx = myModel.indexOf(cfg_weatherProvider)
        if (idx !== -1) combo.currentIndex = idx
    }
    
    ComboBox {
        id: combo
        model: ["Option A", "Option B"]
        // 3. Map UI -> Config (When user changes value)
        onCurrentIndexChanged: {
            page.cfg_weatherProvider = model[currentIndex]
        }
    }
}
```

## Best Practices
- Use `Kirigami.FormLayout` for nice alignment of labels and fields.
- Use `QtQuick.Controls` (e.g. 2.0/2.5) instead of `PlasmaComponents` for the config window, as it matches the application style (like System Settings) rather than the desktop widget style.
- Use `i18n("String")` for all user-facing text.

## Source
Learned from: https://zren.github.io/kde/docs/widget/#configuration

# Gemini KChat Refinement Implementation Plan

## Goal
Address user feedback to refine the Gemini KChat widget: fix the "Learn" tab, update model selection with detailed descriptions, and rename the "General" tab to "Appearance".

## User Review Required
> [!NOTE]
> **Model Descriptions**: I will add the specific Turkish descriptions provided for each model in the configuration dropdown.

## Proposed Changes

### Configuration
#### [MODIFY] [ConfigAppearance.qml](file:///home/mcc45tr/Gitler/Projelerim/Plasma6Widgets/gemini-kchat-fork/contents/ui/ConfigAppearance.qml)
- **Model List**: Update to include:
    - Gemini 3 Pro ("gemini-3.0-pro-exp" or similar if available, otherwise assume placeholder ID)
    - Gemini 3 Flash
    - Gemini 2.5 Pro
    - Gemini 2.5 Flash
    - Gemma 3
- **Descriptions**: Add a dynamic text block showing the description for the selected model.

#### [FIX] [MessageDelegate.qml](file:///home/mcc45tr/Gitler/Projelerim/Plasma6Widgets/gemini-kchat-fork/contents/ui/components/MessageDelegate.qml)
- **Text Visibility**: Ensure text color adapts correctly to the theme (light/dark mode) or enforce a visible color. The user reported not seeing their own text or the API response.

#### [MODIFY] [config.qml](file:///home/mcc45tr/Gitler/Projelerim/Plasma6Widgets/gemini-kchat-fork/contents/config/config.qml)
- **Rename**: Change "General" category name to "Appearance" (TR: "Görünüş").
- **Fix Paths**: Verify and fix `source` paths for all tabs to ensure they load correctly (using `../ui/` relative path).

#### [FIX] [ConfigLearn.qml](file:///home/mcc45tr/Gitler/Projelerim/Plasma6Widgets/gemini-kchat-fork/contents/ui/ConfigLearn.qml)
- Review code for layout or import errors that might prevent loading.

## Verification Plan
### Manual Verification
1.  **Settings**: Open Widget Settings.
2.  **Tabs**: Check tab names: "Appearance" (Görünüş), "Persona & Safety", "Learn".
3.  **Learn Tab**: Click "Learn" and verify content appears.
4.  **Models**: Select "Gemini 3 Pro" in Appearance tab. Verify description: "State-of-the-art Reasoning..."

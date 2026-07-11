# 🕒 Analog Clock Widget for Plasma 6

A sophisticated and minimal Analog Clock widget designed for the KDE Plasma 6 environment. It goes beyond traditional clock widgets by featuring an adaptive geometric layout and interactive states.

## ✨ Key Features

*   **Adaptive Squircle Layout**: Unlike standard circular clocks, this widget uses advanced math to project hands and ticks onto a **Rounded Rectangle (Squircle)** shape, making it fit perfectly with modern UI elements.
*   **Interactive Morphing**: Hover over the widget to see it elegantly morph from a rectangular state to a **traditional circular clock face**.
*   **Dynamic Reveal**: Numerical hour markers and a precise **second hand** are revealed only when you interact with the widget, keeping the idle view clean and distraction-free.
*   **Visual Second Tracker**: 60 dynamic ticks around the border light up as seconds pass, providing a subtle but clear time progression.
*   **System Integration**: Automatically adopts your system's color scheme via the Kirigami theme engine for a native look and feel.
*   **Responsive Animations**: Smooth transitions for hand movements, color shifts, and layout changes.

## 📦 Installation

1.  Download the `.plasmoid` file (if available) or clone the repository.
2.  Install using the command line:
    ```bash
    kpackagetool6 -t Plasma/Applet --install com.mcc45tr.analogclock
    ```
    Or if you are upgrading:
    ```bash
    kpackagetool6 -t Plasma/Applet --upgrade com.mcc45tr.analogclock
    ```

## 🛠️ Requirements
*   **KDE Plasma 6.0+**
*   **Qt 6.x**

---
*Created by MCC45TR*

# MSelective Reboot

MSelective Reboot is a sophisticated reboot widget for the KDE Plasma 6 desktop environment. It provides a streamlined interface for rebooting directly into specific bootloader entries or UEFI Firmware settings, tailored for multi-boot users and developers.

## Features

### Advanced Bootloader Integration
The widget automatically detects and lists entries from both **systemd-boot** and **GRUB** configurations. It eliminates the need to navigate through the bootloader menu manually during the system restart process.

### Intelligent Windows Version Detection
By scanning mounted NTFS partitions, the widget identifies the Windows kernel (`ntoskrnl.exe`) and extracts its build number. This allows for precise labeling, such as "Windows 11" or "Windows 10", instead of generic bootloader titles.

### Safety-First Execution
To prevent accidental restarts, the widget implements a robust confirmation logic. A double-click or double-press is required to initiate a reboot, accompanied by a visual countdown and an immediate cancellation option.

### Versatile Display Modes
*   **Standard List View:** A clean, vertical arrangement optimized for efficiency and secondary displays.
*   **Single Card View:** A paginated, large-scale interface designed for a premium aesthetic and high-resolution monitors.

### Granular Customization
Through the configuration interface, users can:
*   Hide specific boot entries.
*   Rename entries with custom titles.
*   Assign unique icons to individual entries.
*   Adjust list item dimensions and visual margins.

### Adaptive Design
The widget dynamically adjusts its background opacity and corner radius when placed in a Plasma panel, ensuring a seamless visual integration with the system theme and surrounding applets.

## Installation

To install the widget, execute the following command in the project directory:

```bash
./install_all.sh plasma-mselectivereboot
```

## License

This project is licensed under the **GPL-3.0** License.

# Surface Arch Linux Installation Guide

This repository contains scripts to install Arch Linux on Microsoft Surface devices with full hardware support including WiFi, touch screen, Surface keyboard, and a choice between KDE Plasma or Hyprland desktop environments.

## Features

### Surface-Specific Support
- ✅ **Linux Surface Kernel** - Optimized kernel for Surface devices
- ✅ **WiFi Support** - iwd backend for reliable wireless connectivity
- ✅ **Touch Screen** - Full iptsd support for multi-touch
- ✅ **Surface Keyboard** - Type Cover and on-screen keyboard support
- ✅ **Pen/Stylus** - Wacom tablet support for Surface Pen
- ✅ **Detachable Keyboard** - Surface DTX daemon for Book/Go series
- ✅ **Firmware** - Surface-specific IPTS firmware

### Desktop Environment Options
- **KDE Plasma** - Full-featured desktop with Wayland session
- **Hyprland** - Modern tiling Wayland compositor optimized for touch gestures

## Installation Steps

### 1. Boot from Arch Linux USB

Download Arch Linux ISO from [archlinux.org](https://archlinux.org/download/) and create a bootable USB.

### 2. Connect to WiFi (if needed)

```bash
iwctl
[iwd]# device list
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "YOUR_NETWORK_NAME"
[iwd]# exit
```

### 3. Download and Run Surface Installation Script

```bash
# Download the Surface-specific installer
curl -LO https://raw.githubusercontent.com/macaricol/arch/main/surface_install.sh

# Make it executable
chmod +x surface_install.sh

# Run the installer
./surface_install.sh
```

The script will:
- Guide you through drive selection with an interactive menu
- Partition the drive (EFI, swap, root with btrfs)
- Install base system with Surface Linux kernel
- Configure Surface-specific packages and firmware
- Set up WiFi with iwd backend
- Enable touch screen and keyboard support
- Download the post-installation script

### 4. Reboot

After the installation completes, the system will reboot automatically.

### 5. Run Post-Installation Script

After rebooting and logging in:

```bash
./surface_post.sh
```

This script will:
- Present a menu to choose between KDE Plasma or Hyprland
- Install common packages and Surface-optimized tools
- Install and configure your chosen desktop environment
- Set up hardware acceleration and touch gestures
- Install the yay AUR helper

### 6. Desktop Environment Specific Setup

#### For KDE Plasma:
After installation, reboot and log in through SDDM, then run:

```bash
./kde_init.sh
```

This configures:
- Dark theme
- Modern clock widget
- Vertical taskbar on the left
- Screen edge gestures
- Dolphin file manager settings

#### For Hyprland:
After installation and reboot, Hyprland will start automatically. Run the initialization script:

```bash
./hyprland_init.sh
```

This configures:
- Surface-optimized environment variables
- Touch gesture support (3-finger swipe for workspace switching)
- Screen rotation script for tablet mode
- Hardware acceleration
- Waybar status bar
- Rofi application launcher

**Hyprland Keyboard Shortcuts:**
- `Super + Q` - Terminal
- `Super + R` - App launcher
- `Super + E` - File manager
- `Super + C` - Close window
- `Super + F` - Fullscreen
- `Super + 1-9` - Switch workspaces
- `Print Screen` - Screenshot (select area)
- Brightness/Volume keys - Work as expected

**Screen Rotation (Tablet Mode):**
```bash
surface-rotate [normal|right|inverted|left]
```

## Files in This Repository

- **surface_install.sh** - Main installation script for Surface devices
- **surface_post.sh** - Post-installation script with desktop environment selection
- **kde_init.sh** - KDE Plasma configuration script
- **hyprland_init.sh** - Hyprland configuration and optimization script
- **install.sh** - Standard installation script (non-Surface)
- **post.sh** - Standard post-installation script (non-Surface)

## Surface-Specific Features

### WiFi Configuration
The installation uses `iwd` as the WiFi backend for better performance and reliability on Surface devices. NetworkManager is configured to use iwd automatically.

### Touch Screen
The `iptsd` daemon is enabled for full multi-touch support. Both desktop environments are configured for touch input.

### Surface Keyboard
Full support for Type Cover including function keys, backlight control, and media keys.

### Surface Pen
Wacom tablet drivers are installed for Surface Pen with pressure sensitivity support.

### Battery Management
Power management is optimized with:
- KDE Plasma: PowerDevil
- Hyprland: Built-in power management + brightnessctl

### Display Scaling
Both environments are configured with appropriate scaling for high-DPI Surface displays:
- KDE Plasma: Automatic DPI detection
- Hyprland: 1.5x scaling (adjustable in config)

## Troubleshooting

### WiFi Not Working
```bash
# Check if iwd is running
sudo systemctl status iwd

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Connect manually
sudo iwctl
```

### Touch Screen Not Responding
```bash
# Check iptsd status
sudo systemctl status iptsd

# Restart the service
sudo systemctl restart iptsd
```

### Surface Keyboard Not Working
```bash
# Check for Surface modules
lsmod | grep surface

# Reload modules if needed
sudo modprobe -r surface_aggregator_registry
sudo modprobe surface_aggregator_registry
```

### Hyprland Touch Gestures Not Working
Make sure the configuration includes gesture support:
```bash
cat ~/.config/hypr/hyprland.conf | grep gestures
```

## Post-Installation Recommendations

1. **Update System Regularly**
   ```bash
   sudo pacman -Syu
   ```

2. **Install Additional Software**
   ```bash
   yay -S <package-name>
   ```

3. **Configure Power Management**
   - Adjust power profiles in system settings
   - Configure suspend/hibernate settings

4. **Set Up Bluetooth**
   ```bash
   sudo systemctl enable bluetooth
   sudo systemctl start bluetooth
   ```

5. **Configure Automatic Rotation** (for tablet mode)
   - KDE: Use KScreen rotation settings
   - Hyprland: Use `surface-rotate` script

## Credits

- [Linux Surface Project](https://github.com/linux-surface/linux-surface) - Surface kernel and drivers
- [Hyprland](https://hyprland.org/) - Dynamic tiling Wayland compositor
- [KDE Plasma](https://kde.org/plasma-desktop/) - Desktop environment

## License

MIT License - Feel free to modify and distribute these scripts.

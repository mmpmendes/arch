# Quick Start Guide for Surface Installation

## Step-by-Step Process

### 1. Boot from Arch USB

### 2. Connect to WiFi (if needed)
```bash
iwctl
station wlan0 connect "YOUR_NETWORK"
exit
```

### 3. Run Surface Installer
```bash
curl -LO https://raw.githubusercontent.com/macaricol/arch/main/surface_install.sh
chmod +x surface_install.sh
./surface_install.sh
```

**What happens:**
- Interactive drive selection menu
- Automatic partitioning (EFI + Swap + Btrfs root)
- Linux Surface kernel installation
- WiFi setup with iwd
- Touch screen & keyboard drivers
- Downloads surface_post.sh to your home directory

### 4. Reboot (automatic)

### 5. Login and Run Post-Install
```bash
./surface_post.sh
```

**Interactive menu appears:**
- Choose: KDE Plasma OR Hyprland
- Automatic installation of selected DE
- Surface-optimized configuration

### 6. Desktop-Specific Setup

**If you chose KDE Plasma:**
```bash
# After reboot and SDDM login
./kde_init.sh
```

**If you chose Hyprland:**
```bash
# After reboot
./hyprland_init.sh
```

## What's Installed

### All Setups Include
- Linux Surface kernel & firmware
- WiFi (iwd + NetworkManager)
- Touch screen support (iptsd)
- Surface keyboard/Type Cover
- Surface Pen/stylus (wacom)
- Pipewire audio
- Basic applications (Firefox, file manager, etc.)
- yay AUR helper

### KDE Plasma
- Full Plasma desktop with Wayland
- SDDM display manager
- Dolphin, Konsole, Kate, etc.
- Custom widgets and themes

### Hyprland
- Tiling Wayland compositor
- Waybar status bar
- Rofi launcher
- Kitty terminal
- Thunar file manager
- Touch gesture support

## Key Features for Surface

✅ **WiFi** - Works out of the box with iwd
✅ **Touch Screen** - Multi-touch with 10 points
✅ **Keyboard** - Type Cover fully supported
✅ **Pen** - Surface Pen with pressure
✅ **Gestures** - 3-finger swipe (Hyprland) or KDE gestures
✅ **Rotation** - Tablet mode supported
✅ **Brightness** - Fn keys work
✅ **Battery** - Power management optimized

## After Installation

### Connect to WiFi
- **KDE:** Use system tray WiFi icon
- **Hyprland:** Use nm-applet in tray or `nmtui` in terminal

### Install More Software
```bash
yay -S package-name
```

### Update System
```bash
sudo pacman -Syu
```

### Hyprland Shortcuts
- `Super + Q` - Terminal
- `Super + R` - App launcher  
- `Super + E` - File manager
- `Super + C` - Close window
- `Super + 1-9` - Switch workspace

### Rotate Screen (Tablet Mode)
```bash
surface-rotate [normal|right|inverted|left]
```

## Troubleshooting

**WiFi not working:**
```bash
sudo systemctl restart NetworkManager
```

**Touch screen not responding:**
```bash
sudo systemctl restart iptsd
```

**Keyboard not detected:**
```bash
sudo modprobe -r surface_aggregator_registry
sudo modprobe surface_aggregator_registry
```

## Files Created During Installation

| File | Location | Purpose |
|------|----------|---------|
| surface_post.sh | ~/surface_post.sh | Desktop environment installer |
| kde_init.sh | ~/kde_init.sh | KDE configuration (if chosen) |
| hyprland_init.sh | ~/hyprland_init.sh | Hyprland optimization (if chosen) |
| hyprland_shortcuts.txt | ~/hyprland_shortcuts.txt | Keyboard shortcuts reference |

---

**Full documentation:** See SURFACE_README.md

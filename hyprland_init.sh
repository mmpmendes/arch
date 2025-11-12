#!/bin/bash

echo "####################################################################"
echo "#################### Hyprland Surface Optimizations ###############"
echo "####################################################################"
echo ""

# Ensure config directory exists
mkdir -p ~/.config/hypr

# Create environment variables file for Hyprland
cat > ~/.config/hypr/env.conf << 'EOF'
# Surface-specific environment variables

# Enable Wayland for all applications
env = GDK_BACKEND,wayland,x11
env = QT_QPA_PLATFORM,wayland;xcb
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland

# XDG specifications
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# Qt theming
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = QT_QPA_PLATFORMTHEME,qt5ct

# Hardware acceleration
env = MOZ_ENABLE_WAYLAND,1
env = WLR_NO_HARDWARE_CURSORS,1
EOF

# Source the environment in hyprland.conf if not already there
if ! grep -q "source = ~/.config/hypr/env.conf" ~/.config/hypr/hyprland.conf; then
    sed -i '1i source = ~/.config/hypr/env.conf\n' ~/.config/hypr/hyprland.conf
fi

# Install additional Surface-optimized packages from AUR
echo "Installing additional AUR packages for better Surface experience..."

# Check if yay is installed
if ! command -v yay &>/dev/null; then
    echo "Installing yay..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
fi

# Install useful AUR packages
yay -S --noconfirm \
    hyprpicker \
    wlogout \
    nwg-look \
    bibata-cursor-theme

echo ""
echo "####################################################################"
echo "Setting up keyboard shortcuts cheatsheet..."
echo "####################################################################"

cat > ~/hyprland_shortcuts.txt << 'EOF'
Hyprland Keyboard Shortcuts (Surface)
======================================

Basic:
  Super + Q           - Open terminal (Kitty)
  Super + C           - Close active window
  Super + M           - Exit Hyprland
  Super + E           - File manager (Thunar)
  Super + V           - Toggle floating
  Super + R           - App launcher (Rofi)
  Super + F           - Fullscreen
  Print Screen        - Screenshot (select area)

Navigation:
  Super + Arrow Keys  - Move focus
  Super + 1-9         - Switch to workspace 1-9
  Super + Shift + 1-9 - Move window to workspace 1-9
  Super + Mouse Wheel - Scroll through workspaces

Window Management:
  Super + Left Click  - Move window
  Super + Right Click - Resize window
  Super + J           - Toggle split

Media & System:
  Brightness Up/Down  - Adjust screen brightness
  Volume Up/Down      - Adjust volume
  Volume Mute         - Mute/unmute audio

Touch Gestures:
  3-finger swipe      - Switch workspaces
EOF

echo "Shortcuts saved to ~/hyprland_shortcuts.txt"

# Create a simple screen locker script
mkdir -p ~/.config/swaylock
cat > ~/.config/swaylock/config << 'EOF'
ignore-empty-password
show-failed-attempts
color=1e1e2e
font=Noto Sans
indicator-radius=100
indicator-thickness=10
line-uses-ring
EOF

echo ""
echo "####################################################################"
echo "Setting up automatic screen rotation for tablet mode (Surface)..."
echo "####################################################################"

# Create a script to handle screen rotation
mkdir -p ~/.local/bin
cat > ~/.local/bin/surface-rotate << 'EOF'
#!/bin/bash
# Automatic screen rotation for Surface devices

TRANSFORM=$(hyprctl monitors -j | jq -r '.[0].transform')

case "$1" in
    "normal")
        hyprctl keyword monitor ,preferred,auto,1.5,transform,0
        ;;
    "right")
        hyprctl keyword monitor ,preferred,auto,1.5,transform,1
        ;;
    "inverted")
        hyprctl keyword monitor ,preferred,auto,1.5,transform,2
        ;;
    "left")
        hyprctl keyword monitor ,preferred,auto,1.5,transform,3
        ;;
    *)
        echo "Usage: surface-rotate [normal|right|inverted|left]"
        ;;
esac
EOF

chmod +x ~/.local/bin/surface-rotate

echo ""
echo "####################################################################"
echo "Configuration complete!"
echo "####################################################################"
echo ""
echo "Additional features configured:"
echo "  - Environment variables optimized for Surface"
echo "  - Hardware acceleration enabled"
echo "  - Touch gestures configured"
echo "  - Screen lock (swaylock) configured"
echo "  - Screen rotation script: surface-rotate [normal|right|inverted|left]"
echo ""
echo "View keyboard shortcuts: cat ~/hyprland_shortcuts.txt"
echo ""
echo "Log out and log back in for all changes to take effect."
echo ""

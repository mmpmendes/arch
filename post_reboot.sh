#!/bin/bash

# Ensure stdin is bound to the terminal
exec </dev/tty

# ============================================================
# CONFIGURATION — edit these values before running the script
# ============================================================
DESKTOP='hyprland'          # options: hyprland, kde
KBD_LAYOUT='pt'
HYPR_TERMINAL='kitty'       # used only when DESKTOP=hyprland

detect_gpu() {
    sudo pacman -S --noconfirm --needed pciutils

    local gpu
    gpu=$(lspci | grep -Ei 'VGA|3D|Display')

    if echo "$gpu" | grep -qi 'amd\|radeon'; then
        echo "Detected AMD GPU"
        GPU_PACKAGES='mesa vulkan-radeon libva-mesa-driver mesa-vdpau radeontop'
    elif echo "$gpu" | grep -qi 'nvidia'; then
        echo "Detected NVIDIA GPU"
        GPU_PACKAGES='nvidia nvidia-utils nvidia-settings'
    elif echo "$gpu" | grep -qi 'intel'; then
        echo "Detected Intel GPU"
        GPU_PACKAGES='mesa vulkan-intel intel-media-driver'
    else
        echo "Warning: Could not detect GPU vendor. No GPU drivers will be installed."
        GPU_PACKAGES=''
    fi

    if grep -q 'AuthenticAMD' /proc/cpuinfo; then
        GPU_PACKAGES="amd-ucode $GPU_PACKAGES"
    elif grep -q 'GenuineIntel' /proc/cpuinfo; then
        GPU_PACKAGES="intel-ucode $GPU_PACKAGES"
    fi
}

# Update the system before installing packages
sudo pacman -Syu

clear
echo "####################################################################"
echo "#################### Install desktop environment ####################"
echo "####################################################################"

if [ "$DESKTOP" = "hyprland" ]; then
    sudo pacman -S --noconfirm hyprland waybar kitty wofi hyprpaper hyprlock mako \
        xdg-desktop-portal-hyprland polkit-gnome grim slurp wl-clipboard
    sudo pacman -S --noconfirm pipewire wireplumber pipewire-pulse pavucontrol
elif [ "$DESKTOP" = "kde" ]; then
    sudo pacman -S --noconfirm plasma-desktop sddm-kcm bluedevil kscreen konsole \
        kate kwalletmanager dolphin ark kdegraphics-thumbnailers ffmpegthumbs \
        plasma-pa plasma-nm gwenview plasma-systemmonitor kde-gtk-config kio-admin krdc
fi

sudo pacman -S --noconfirm sddm

clear
echo "####################################################################"
echo "################ Enable and start Bluetooth service ################"
echo "####################################################################"

sudo systemctl start bluetooth.service
sudo systemctl enable bluetooth.service

clear
echo "####################################################################"
echo "##################### Install CPU/GPU packages #####################"
echo "####################################################################"

detect_gpu
[ -n "$GPU_PACKAGES" ] && sudo pacman -S --noconfirm $GPU_PACKAGES

clear
echo "####################################################################"
echo "###################### Install extra packages ######################"
echo "####################################################################"

sudo pacman -S --noconfirm fastfetch mpv freerdp ttf-liberation firefox git code

clear
echo "####################################################################"
echo "####################### Setting up Fast Boot #######################"
echo "####################################################################"

grep -q '^GRUB_DEFAULT=' /etc/default/grub \
    && sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub \
    || echo 'GRUB_DEFAULT=0' | sudo tee -a /etc/default/grub > /dev/null
sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

clear
echo "####################################################################"
echo "###################### Setting up Login Screen #####################"
echo "####################################################################"

if [ "$DESKTOP" = "kde" ]; then
    sudo git clone -b master --depth 1 https://github.com/macaricol/sddm-astronaut-theme.git \
        /usr/share/sddm/themes/sddm-astronaut-theme
    sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/

    SDDM_CONFIG_DIR="/etc/sddm.conf.d"
    KDE_SETTINGS_FILE="/etc/sddm.conf.d/kde_settings.conf"
    [[ -d "$SDDM_CONFIG_DIR" ]] || sudo mkdir -p "$SDDM_CONFIG_DIR"

    sudo tee "$KDE_SETTINGS_FILE" > /dev/null << 'EOF'
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=sddm-astronaut-theme

[Users]
MaximumUid=60513
MinimumUid=1000
EOF

    if grep -q "^Current=sddm-astronaut-theme" "$KDE_SETTINGS_FILE"; then
        echo "Confirmed: SDDM theme is set."
    else
        echo "Error: Failed to set SDDM theme."
    fi
fi

clear
echo "####################################################################"
echo "######################## Setting mpv configs #######################"
echo "####################################################################"

MPV_DIR="/etc/mpv"
MPV_CONFIG_FILE="/etc/mpv/input.conf"
[[ -d "$MPV_DIR" ]] || sudo mkdir -p "$MPV_DIR"

sudo tee "$MPV_CONFIG_FILE" > /dev/null << 'EOF'
WHEEL_UP      seek 10                  # seek 10 seconds forward
WHEEL_DOWN    seek -10                 # seek 10 seconds backward
WHEEL_LEFT    add volume -2
WHEEL_RIGHT   add volume 2
EOF

if grep -q "WHEEL_UP.*seek 10" "$MPV_CONFIG_FILE"; then
    echo "Confirmed: mpv input.conf is set."
else
    echo "Error: Failed to create $MPV_CONFIG_FILE."
fi

clear
echo "####################################################################"
echo "#################### Setting up desktop configs ####################"
echo "####################################################################"

if [ "$DESKTOP" = "hyprland" ]; then
    mkdir -p "$HOME/.config/hypr"

    cat > "$HOME/.config/hypr/hyprland.conf" << EOF
# Autostart
exec-once = waybar
exec-once = hyprpaper
exec-once = mako
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# Wayland compatibility
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland

\$terminal = $HYPR_TERMINAL
\$menu = wofi --show drun

input {
    kb_layout = $KBD_LAYOUT
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
}

\$mod = SUPER
bind = \$mod, Return, exec, \$terminal
bind = \$mod, D, exec, \$menu
bind = \$mod, Q, killactive
bind = \$mod, F, fullscreen
bind = \$mod SHIFT, E, exit
bind = \$mod, 1, workspace, 1
bind = \$mod, 2, workspace, 2
bind = \$mod, 3, workspace, 3
bind = \$mod, 4, workspace, 4
bind = \$mod, 5, workspace, 5
bind = \$mod SHIFT, 1, movetoworkspace, 1
bind = \$mod SHIFT, 2, movetoworkspace, 2
bind = \$mod SHIFT, 3, movetoworkspace, 3
bind = \$mod SHIFT, 4, movetoworkspace, 4
bind = \$mod SHIFT, 5, movetoworkspace, 5
bind = \$mod, H, movefocus, l
bind = \$mod, L, movefocus, r
bind = \$mod, K, movefocus, u
bind = \$mod, J, movefocus, d
bind = , Print, exec, grim -g "\$(slurp)" - | wl-copy
EOF

    cat > "$HOME/.config/hypr/hyprpaper.conf" << 'EOF'
# Add your wallpaper:
# preload = /path/to/image.jpg
# wallpaper = ,/path/to/image.jpg
EOF

    cat > "$HOME/.config/hypr/hyprlock.conf" << 'EOF'
background {
    blur_passes = 3
}

input-field {
    size = 300, 50
    position = 0, -80
    halign = center
    valign = center
}
EOF

elif [ "$DESKTOP" = "kde" ]; then
    mkdir -p "$HOME/.config"
    KEYB_FILE="$HOME/.config/kxkbrc"

    tee "$KEYB_FILE" > /dev/null << EOF
[Layout]
LayoutList=$KBD_LAYOUT
Use=true
EOF

    WALLPAPER_FILE="/usr/share/sddm/themes/sddm-astronaut-theme/Wallpapers/cyberpunk2077.jpg"
    if [ ! -f "$WALLPAPER_FILE" ]; then
        echo "Warning: Wallpaper file not found, skipping wallpaper setup."
    else
        tee "$HOME/.config/kscreenlockerrc" > /dev/null << EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=$WALLPAPER_FILE
PreviewImage=$WALLPAPER_FILE
EOF

        tee "$HOME/.config/plasmarc" > /dev/null << EOF
[Wallpapers]
usersWallpapers=$WALLPAPER_FILE
EOF

        XML_FILE="/usr/share/plasma/wallpapers/org.kde.image/contents/config/main.xml"
        sudo chmod 644 "$WALLPAPER_FILE"
        sudo sed -i "/<entry name=\"Image\" type=\"String\">/,/<\/entry>/ s|<default>.*</default>|<default>file://$WALLPAPER_FILE</default>|" "$XML_FILE"

        if grep -q "file://$WALLPAPER_FILE" "$XML_FILE"; then
            echo "Wallpaper configured."
        else
            echo "Error: Failed to update wallpaper XML."
        fi
    fi
fi

echo "####################################################################"
echo "################## Enabling and starting sddm service ##############"
echo "####################################################################"
# This needs to be run last otherwise it will exit the running script and present the login GUI

sudo systemctl enable sddm
sudo systemctl start sddm

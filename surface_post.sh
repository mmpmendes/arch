#!/bin/bash
set -eo pipefail

# ── Colors ───────────────────────────────────────────────────────────
BOLD='\e[1m' BGREEN='\e[92m' BYELLOW='\e[93m' BRED='\e[91m' RESET='\e[0m'

info_print() { printf "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] %b${RESET}\n" "$1"; }
warn_print() { printf "${BOLD}${BYELLOW}[ ${BRED}!${BYELLOW} ] %b${RESET}\n" "$1"; }

# ── Redirect stdin from TTY ──────────────────────────────────────────
exec < /dev/tty

# ── Desktop Environment Selection Menu ──────────────────────────────
select_desktop() {
  local options=("KDE Plasma" "Hyprland")
  local selected=0 total=${#options[@]}

  draw_menu() {
    clear
    info_print "###########################################"
    info_print "#    Select Desktop Environment (Surface) #"
    info_print "###########################################"
    info_print ""

    for ((i=0; i<total; i++)); do
      [[ $i -eq $selected ]] && \
        info_print "# > \033[7m${options[i]}\033[0m" || \
        info_print "#   ${options[i]}  "
    done

    info_print ""
    info_print "###########################################"
    info_print "#   ↑↓ to navigate, Enter to select       #"
    info_print "###########################################"
  }

  read_key() {
    local key
    read -rsn1 key
    [[ $key == $'\x1b' ]] && read -rsn2 -t 0.1 key && case $key in
      '[A') ((selected--)); (( selected < 0 )) && selected=$((total-1)) ;;
      '[B') ((selected++)); (( selected >= total )) && selected=0 ;;
    esac
    [[ -z $key ]] && return 0  # Enter pressed
    return 1
  }

  while :; do
    draw_menu
    read_key && break
  done

  DESKTOP_ENV=${options[selected]}
  info_print "Selected: $DESKTOP_ENV"
}

# ── Common packages ──────────────────────────────────────────────────
install_common_packages() {
  info_print "Installing common packages and Surface-specific tools..."
  
  sudo pacman -Syu --noconfirm \
    git base-devel wget curl \
    mesa vulkan-radeon vulkan-intel \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    firefox chromium \
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji \
    btop htop neofetch \
    grim slurp wl-clipboard xdg-desktop-portal \
    libva-mesa-driver mesa-vdpau \
    brightnessctl playerctl \
    polkit gnome-keyring \
    gvfs gvfs-mtp \
    unzip zip p7zip unrar \
    man-db man-pages \
    cmake meson ninja \
    libnotify dunst
  
  info_print "Installing Surface-specific packages..."
  sudo pacman -S --noconfirm \
    libwacom-surface \
    xf86-input-wacom
}

# ── Install KDE Plasma ──────────────────────────────────────────────
install_kde() {
  info_print "Installing KDE Plasma..."
  
  sudo pacman -S --noconfirm \
    plasma-meta plasma-wayland-session \
    kde-applications-meta \
    sddm sddm-kcm \
    konsole dolphin kate gwenview okular spectacle \
    ark filelight kcalc kwrite \
    packagekit-qt6 \
    plasma-systemmonitor \
    kscreen \
    powerdevil \
    bluedevil \
    plasma-nm \
    plasma-pa \
    kinfocenter \
    wacomtablet

  info_print "Enabling SDDM..."
  sudo systemctl enable sddm

  info_print "Downloading KDE init script..."
  curl -fsSL https://raw.githubusercontent.com/macaricol/arch/refs/heads/main/kde_init.sh -o ~/kde_init.sh
  chmod +x ~/kde_init.sh
  
  info_print "KDE Plasma installed. Run ~/kde_init.sh after first login to configure."
}

# ── Install Hyprland ────────────────────────────────────────────────
install_hyprland() {
  info_print "Installing Hyprland..."
  
  sudo pacman -S --noconfirm \
    hyprland xdg-desktop-portal-hyprland \
    waybar rofi-wayland \
    kitty thunar \
    swaylock-effects swayidle \
    polkit-kde-agent \
    qt5-wayland qt6-wayland \
    thunar-archive-plugin thunar-volman \
    network-manager-applet \
    pavucontrol \
    blueman \
    kvantum \
    swaync
  
  info_print "Creating Hyprland configuration with Surface optimizations..."
  mkdir -p ~/.config/hypr
  
  cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Hyprland config for Surface devices

# Monitor config (adjust as needed)
monitor=,preferred,auto,1.5

# Surface-specific input config
input {
    kb_layout = pt
    kb_variant = nodeadkeys
    follow_mouse = 1
    touchpad {
        natural_scroll = yes
        tap-to-click = yes
        disable_while_typing = yes
        scroll_factor = 0.3
    }
    sensitivity = 0
    accel_profile = adaptive
}

# Touch gestures
gestures {
    workspace_swipe = on
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
}

# General settings
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decoration
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layout
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Window rules for Surface
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$

# Key bindings
$mainMod = SUPER

bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, fullscreen,

# Screenshot
bind = , PRINT, exec, grim -g "$(slurp)" - | wl-copy

# Brightness control
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Volume control
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Autostart
exec-once = waybar
exec-once = swaync
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = nm-applet --indicator
exec-once = blueman-applet
EOF

  info_print "Creating Waybar configuration..."
  mkdir -p ~/.config/waybar
  
  cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],
    
    "hyprland/workspaces": {
        "format": "{name}"
    },
    
    "clock": {
        "format": "{:%H:%M | %a %d %b}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " Connected",
        "format-disconnected": "⚠ Disconnected",
        "tooltip-format": "{ifname}: {ipaddr}"
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " Muted",
        "format-icons": {
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    },
    
    "tray": {
        "spacing": 10
    }
}
EOF

  cat > ~/.config/waybar/style.css << 'EOF'
* {
    font-family: "Noto Sans", sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(30, 30, 46, 0.8);
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 10px;
    color: #cdd6f4;
}

#workspaces button.active {
    background: rgba(137, 180, 250, 0.3);
}

#clock, #battery, #network, #pulseaudio, #tray {
    padding: 0 10px;
}

#battery.warning {
    color: #f9e2af;
}

#battery.critical {
    color: #f38ba8;
}
EOF

  info_print "Creating rofi configuration..."
  mkdir -p ~/.config/rofi
  cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    modi: "drun,run";
    show-icons: true;
    display-drun: "Apps";
    display-run: "Run";
}

@theme "/usr/share/rofi/themes/Arc-Dark.rasi"
EOF

  info_print "Hyprland installed and configured for Surface!"
  info_print "Log out and select Hyprland from the display manager."
}

# ── Install yay (AUR helper) ────────────────────────────────────────
install_yay() {
  info_print "Installing yay (AUR helper)..."
  
  if command -v yay &>/dev/null; then
    info_print "yay already installed, skipping..."
    return
  fi
  
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~
  rm -rf /tmp/yay
  
  info_print "yay installed successfully!"
}

# ── Main ────────────────────────────────────────────────────────────
main() {
  info_print "Surface Post-Installation Script"
  info_print "================================="
  
  # Select desktop environment
  select_desktop
  
  # Install common packages
  install_common_packages
  
  # Install yay
  install_yay
  
  # Install selected desktop environment
  case "$DESKTOP_ENV" in
    "KDE Plasma")
      install_kde
      ;;
    "Hyprland")
      install_hyprland
      ;;
  esac
  
  info_print ""
  info_print "================================="
  info_print "Installation complete!"
  info_print "================================="
  info_print ""
  
  if [[ "$DESKTOP_ENV" == "KDE Plasma" ]]; then
    info_print "To start using your system:"
    info_print "1. Reboot: sudo reboot"
    info_print "2. Log in through SDDM"
    info_print "3. Run ~/kde_init.sh to configure KDE"
  else
    info_print "To start using your system:"
    info_print "1. Reboot: sudo reboot"
    info_print "2. Log in and Hyprland will start automatically"
    info_print "   or select it from your display manager"
  fi
  
  info_print ""
  info_print "Surface-specific features enabled:"
  info_print "- Touch screen support (iptsd)"
  info_print "- Surface keyboard support"
  info_print "- WiFi with iwd backend"
  info_print "- Tablet/pen input support"
  info_print "- Detachable keyboard support"
}

main

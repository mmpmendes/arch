#!/bin/bash

# Ensure stdin is bound to the terminal
exec </dev/tty

# Update the system before installing packages
sudo pacman -Syu

clear
echo "####################################################################"
echo "#################### Install minimal essentials ####################"
echo "####################################################################"

sudo pacman -S sddm sddm-kcm plasma-desktop bluedevil kscreen konsole kate kwalletmanager dolphin ark kdegraphics-thumbnailers ffmpegthumbs plasma-pa plasma-nm gwenview plasma-systemmonitor 

sleep 10

clear
echo "####################################################################"
echo "################ Enable and start Bluetooth service ################"
echo "####################################################################"
 
sudo systemctl start bluetooth.service
sudo systemctl enable bluetooth.service

sleep 10

clear
echo "####################################################################"
echo "##################### Install CPU/GPU packages #####################"
echo "####################################################################"

sudo pacman -S amd-ucode
sudo pacman -S mesa vulkan-radeon libva-mesa-driver mesa-vdpau radeontop

sleep 10

clear
echo "####################################################################"
echo "###################### Install extra packages ######################"
echo "####################################################################"

sudo pacman -S fastfetch mpv krdc freerdp ttf-liberation firefox kde-gtk-config kio-admin git

sleep 10


clear
echo "####################################################################"
echo "####################### Setting up Fast Boot #######################"
echo "####################################################################"

sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub

# Update grub configuration
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Comment out all lines containing 'echo' in /boot/grub/grub.cfg
sudo sed -i '/echo/s/^/#/' /boot/grub/grub.cfg

sleep 10

clear
echo "####################################################################"
echo "###################### Setting up Login Screen #####################"
echo "####################################################################"

sudo git clone -b master --depth 1 https://github.com/macaricol/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/

# Define the directory and file
SDDM_CONFIG_DIR="/etc/sddm.conf.d"
KDE_SETTINGS_FILE="/etc/sddm.conf.d/kde_settings.conf"

[[ -d "$SDDM_CONFIG_DIR" ]] || sudo mkdir -p "$SDDM_CONFIG_DIR"

# Create or overwrite the kde_settings.conf file with the specified content
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

echo "Created $KDE_SETTINGS_FILE with the specified content."

# Verify the Current= line in the [Theme] section
if grep -q "^Current=sddm-astronaut-theme" "$KDE_SETTINGS_FILE"; then
    echo "Confirmed: Current=sddm-astronaut-theme is set in $KDE_SETTINGS_FILE"
else
    echo "Error: Failed to set Current=sddm-astronaut-theme in $KDE_SETTINGS_FILE"
fi

sleep 10

clear
echo "####################################################################"
echo "######################## Setting mpv configs #######################"
echo "####################################################################"

# Define the directory and file
MPV_DIR="/etc/mpv"
MPV_CONFIG_FILE="/etc/mpv/input.conf"

[[ -d "$MPV_DIR" ]] || sudo mkdir -p "$MPV_DIR"

# Create or overwrite the input.conf file with the specified content
sudo tee "$MPV_CONFIG_FILE" > /dev/null << 'EOF'
WHEEL_UP      seek 10                  # seek 10 seconds forward
WHEEL_DOWN    seek -10                 # seek 10 seconds backward
WHEEL_LEFT    add volume -2
WHEEL_RIGHT   add volume 2
EOF

echo "Created $MPV_CONFIG_FILE with the specified content."

# Verify the file contents
if grep -q "WHEEL_UP.*seek 10" "$MPV_CONFIG_FILE"; then
    echo "Confirmed: input.conf contains the correct settings."
else
    echo "Error: Failed to create $MPV_CONFIG_FILE with the correct content."
fi

sleep 10

clear
echo "####################################################################"
echo "###################### Setting keyboard layout #####################"
echo "####################################################################"

KDE_CONFIGS_DIR="$HOME/.config"
[[ -d "$KDE_CONFIGS_DIR" ]] || mkdir -p "$KDE_CONFIGS_DIR"

# Define the file path
KEYB_FILE="$KDE_CONFIGS_DIR/kxkbrc"

# Create or overwrite the kxkbrc file with the specified content
tee "$KEYB_FILE" > /dev/null << 'EOF'
[Layout]
LayoutList=pt
Use=true
EOF

echo "Created $KEYB_FILE with the specified content."

sleep 10

clear
echo "####################################################################"
echo "################### Setting Wallpaper / ScreenLock #################"
echo "####################################################################"
# Define the wallpaper file path
WALLPAPER_FILE="/usr/share/sddm/themes/sddm-astronaut-theme/Wallpapers/cyberpunk2077.jpg"

# Check if the wallpaper file exists
if [ ! -f "$WALLPAPER_FILE" ]; then
    echo "Error: Wallpaper file $WALLPAPER_FILE does not exist."
    exit 1
fi

# Define the file paths
SCRLCK_FILE="$KDE_CONFIGS_DIR/kscreenlockerrc"
WALLPATH_FILE="$KDE_CONFIGS_DIR/plasmarc"

# Create or overwrite the kscreenlockerrc file
tee "$SCRLCK_FILE" > /dev/null << EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=$WALLPAPER_FILE
PreviewImage=$WALLPAPER_FILE
EOF

echo "Created $SCRLCK_FILE with the specified content."

sleep 10

# Create or overwrite the plasmarc file
tee "$WALLPATH_FILE" > /dev/null << EOF
[Wallpapers]
usersWallpapers=$WALLPAPER_FILE
EOF

echo "Created $WALLPATH_FILE with the specified content."

sleep 10

APPLETS_CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

# If config file doesn't exist, create it with minimal structure
if [ ! -f "$APPLETS_CONFIG_FILE" ]; then
    echo "Creating config file: $APPLETS_CONFIG_FILE"
    cat > "$APPLETS_CONFIG_FILE" << EOL
[Containments][1]
plugin=org.kde.desktopcontainment
wallpaperplugin=org.kde.image

[Containments][1][Wallpapers][org.kde.image][General]
Image=$WALLPAPER_FILE
EOL
fi

# Set wallpaper using kwriteconfig6
kwriteconfig6 --file "$APPLETS_CONFIG_FILE" \
  --group Containments --group 1 \
  --group Wallpapers --group org.kde.image --group General \
  --key Image "$WALLPAPER_FILE"

echo "Wallpaper set to: $WALLPAPER_FILE"

# Apply changes
kquitapp6 plasmashell && kstart6 plasmashell

sleep 10

# Restart Plasma to apply changes
echo "Restarting Plasma desktop..."
echo "Configuration updated successfully!"

#############################################################
########################## SDDM #############################
#############################################################
# This needs to be run last otherwise it will simply exit running script and present the login GUI

sudo systemctl enable sddm
sudo systemctl start sddm

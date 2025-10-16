#!/bin/bash

# Ensure stdin is bound to the terminal
exec </dev/tty

# Update the system before installing packages
sudo pacman -Syu

# Install minimal essentials
sudo pacman -S sddm sddm-kcm plasma-desktop bluedevil kscreen konsole kate kwalletmanager dolphin ark kdegraphics-thumbnailers ffmpegthumbs plasma-pa plasma-nm gwenview plasma-systemmonitor 

# Enable and start Bluetooth service
sudo systemctl start bluetooth.service
sudo systemctl enable bluetooth.service

# Install CPU/GPU packages
sudo pacman -S amd-ucode
sudo pacman -S mesa vulkan-radeon libva-mesa-driver mesa-vdpau radeontop

# Install extra packages
sudo pacman -S fastfetch mpv krdc freerdp ttf-liberation firefox kde-gtk-config kio-admin git

echo "Installation and service setup complete!"

#############################################################
######################### FAST BOOT ###########################
#############################################################

sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub

# Update grub configuration
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Comment out all lines containing 'echo' in /boot/grub/grub.cfg
sudo sed -i '/echo/s/^/#/' /boot/grub/grub.cfg

echo "GRUB configuration updated and all 'echo' lines in /boot/grub/grub.cfg commented out."

sleep 10

#############################################################
####################### LOGIN SCREEN ##########################
#############################################################
clear

sudo git clone -b master --depth 1 https://github.com/macaricol/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/

# Define the directory and file
SDDM_CONFIG_DIR="/etc/sddm.conf.d"
KDE_SETTINGS_FILE="/etc/sddm.conf.d/kde_settings.conf"

# Create the directory if it doesn't exist
if [[ ! -d "$SDDM_CONFIG_DIR" ]]; then
    echo "Creating directory $SDDM_CONFIG_DIR"
    sudo mkdir -p "$SDDM_CONFIG_DIR"
fi

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

#############################################################
########################## MPV ###############################
#############################################################

# Define the directory and file
MPV_DIR="/etc/mpv"
MPV_CONFIG_FILE="/etc/mpv/input.conf"

# Create the directory if it doesn't exist
if [[ ! -d "$MPV_DIR" ]]; then
    echo "Creating directory $MPV_DIR"
    sudo mkdir -p "$MPV_DIR"
fi

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

#############################################################
########################## KEYBOARD ##########################
#############################################################

KDE_CONFIGS_DIR="$HOME/.config"
sudo bash -c '[[ -d "$KDE_CONFIGS_DIR" ]] || mkdir -p "$KDE_CONFIGS_DIR"'

# Define the file path
KEYB_FILE="$KDE_CONFIGS_DIR/kxkbrc"

# Create or overwrite the kxkbrc file with the specified content
sudo tee "$KEYB_FILE" > /dev/null << 'EOF'
[Layout]
LayoutList=pt
Use=true
EOF

echo "Created $KEYB_FILE with the specified content."
sleep 10

#############################################################
####################### WALLPAPER/SCREENLOCK ##################
#############################################################

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
sudo tee "$SCRLCK_FILE" > /dev/null << EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=$WALLPAPER_FILE
PreviewImage=$WALLPAPER_FILE
EOF

echo "Created $SCRLCK_FILE with the specified content."

# Create or overwrite the plasmarc file
sudo tee "$WALLPATH_FILE" > /dev/null << EOF
[Wallpapers]
usersWallpapers=$WALLPAPER_FILE
EOF

echo "Created $WALLPATH_FILE with the specified content."

# Define the configuration file path
APPLETS_CONFIG_FILE="$KDE_CONFIGS_DIR/plasma-org.kde.plasma.desktop-appletsrc"
# Check if the configuration file exists
if [ -f "$APPLETS_CONFIG_FILE" ]; then
    echo "Configuration file found."
else
    echo "Configuration file not found. Creating a new one..."
    touch "$APPLETS_CONFIG_FILE"
    # Initialize with basic structure
    echo "[Containments][1][Wallpaper][org.kde.image][General]" >> "$APPLETS_CONFIG_FILE"
fi

sleep 10

# Check if the wallpaper section exists in the file
if grep -q "\[Containments\]\[1\]\[Wallpaper\]\[org.kde.image\]\[General\]" "$APPLETS_CONFIG_FILE"; then
    # Check if the Image line already exists
    if grep -q "^Image=" "$APPLETS_CONFIG_FILE"; then
        # Update the existing Image line
        sed -i "/\[Containments\]\[1\]\[Wallpaper\]\[org.kde.image\]\[General\]/,/^$/ s|^Image=.*|Image=$WALLPAPER_FILE|" "$APPLETS_CONFIG_FILE"
        echo "Updated wallpaper path to: $WALLPAPER_FILE"
    else
        # Append the Image line under the section
        sed -i "/\[Containments\]\[1\]\[Wallpaper\]\[org.kde.image\]\[General\]/a Image=$WALLPAPER_FILE" "$APPLETS_CONFIG_FILE"
        echo "Added wallpaper path: $WALLPAPER_FILE"
    fi
else
    # Append the entire section if it doesn't exist
    echo -e "\n[Containments][1][Wallpaper][org.kde.image][General]\nImage=$WALLPAPER_FILE" >> "$APPLETS_CONFIG_FILE"
    echo "Created new wallpaper section with path: $WALLPAPER_FILE"
fi

sleep 10

# Restart Plasma to apply changes
echo "Restarting Plasma desktop..."
#kquitapp5 plasmashell && kstart5 plasmashell &

echo "Configuration updated successfully!"

#############################################################
########################## SDDM #############################
#############################################################
# This needs to be run last otherwise it will simply exit running script and present the login GUI

sudo systemctl enable sddm
sudo systemctl start sddm

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

sleep 5

#############################################################
####################### LOGIN SCREEN ##########################
#############################################################

sudo git clone -b master --depth 1 https://github.com/macaricol/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/

# Define the directory and file
CONFIG_DIR="/etc/sddm.conf.d"
CONFIG_FILE="/etc/sddm.conf.d/kde_settings.conf"

# Create the directory if it doesn't exist
if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "Creating directory $CONFIG_DIR"
    sudo mkdir -p "$CONFIG_DIR"
fi

# Create or overwrite the kde_settings.conf file with the specified content
sudo tee "$CONFIG_FILE" > /dev/null << 'EOF'
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

echo "Created $CONFIG_FILE with the specified content."

# Verify the Current= line in the [Theme] section
if grep -q "^Current=sddm-astronaut-theme" "$CONFIG_FILE"; then
    echo "Confirmed: Current=sddm-astronaut-theme is set in $CONFIG_FILE"
else
    echo "Error: Failed to set Current=sddm-astronaut-theme in $CONFIG_FILE"
fi

#############################################################
########################## MPV ###############################
#############################################################

# Define the directory and file
MPV_DIR="/etc/mpv"
CONFIG_FILE="/etc/mpv/input.conf"

# Create the directory if it doesn't exist
if [[ ! -d "$MPV_DIR" ]]; then
    echo "Creating directory $MPV_DIR"
    sudo mkdir -p "$MPV_DIR"
fi

# Create or overwrite the input.conf file with the specified content
sudo tee "$CONFIG_FILE" > /dev/null << 'EOF'
WHEEL_UP      seek 10                  # seek 10 seconds forward
WHEEL_DOWN    seek -10                 # seek 10 seconds backward
WHEEL_LEFT    add volume -2
WHEEL_RIGHT   add volume 2
EOF

echo "Created $CONFIG_FILE with the specified content."

# Verify the file contents
if grep -q "WHEEL_UP.*seek 10" "$CONFIG_FILE"; then
    echo "Confirmed: input.conf contains the correct settings."
else
    echo "Error: Failed to create $CONFIG_FILE with the correct content."
fi

#############################################################
########################## SDDM #############################
#############################################################
# This needs to be run last otherwise it will simply exit running script and present the login GUI

sudo systemctl enable sddm
sudo systemctl start sddm

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

##### FAST BOOT ####
# Use sed to modify GRUB_TIMEOUT and GRUB_TIMEOUT_STYLE
sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub

# Update grub configuration
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Comment out all lines containing 'echo' in /boot/grub/grub.cfg
sudo sed -i '/echo/s/^/#/' /boot/grub/grub.cfg

echo "GRUB configuration updated and all 'echo' lines in /boot/grub/grub.cfg commented out."

sleep 5

### manual stuff ###
# use transfuse to restore kde user settings
# https://gitlab.com/cscs/transfuse

## login screen theme
## https://github.com/Keyitdev/sddm-astronaut-theme?tab=readme-ov-file
sudo git clone -b master --depth 1 https://github.com/macaricol/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
# Define the file and the desired theme
CONFIG_FILE="/etc/sddm.conf.d/kde_settings.conf"
DESIRED_THEME="sddm-astronaut-theme"
# Replace the Current= line with the desired theme
sudo sed -i "s/^Current=.*/Current=$DESIRED_THEME/" "$CONFIG_FILE"

# This needs to be run last otherwise it will simply exit running script and present the login GUI
# Enable and start SDDM service
sudo systemctl enable sddm
sudo systemctl start sddm

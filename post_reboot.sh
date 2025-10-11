#!/bin/bash

# Update the system before installing packages
sudo pacman -Syu

# Install minimal essentials
sudo pacman -S sddm plasma-desktop bluedevil kscreen konsole dolphin kdegraphics-thumbnailers plasma-pa gwenview plasma-systemmonitor

# Enable and start Bluetooth service
sudo systemctl start bluetooth.service
sudo systemctl enable bluetooth.service

# Install CPU/GPU packages
sudo pacman -S amd-ucode
sudo pacman -S mesa vulkan-radeon libva-mesa-driver mesa-vdpau radeontop

# Install extra packages
sudo pacman -S fastfetch mpv krdc freerdp ttf-liberation firefox

# Enable and start SDDM service
sudo systemctl enable sddm
sudo systemctl start sddm

echo "Installation and service setup complete!"

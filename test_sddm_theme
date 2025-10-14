#!/bin/bash

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

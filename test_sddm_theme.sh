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

#####THUMBNAILS SETTINGS####
#####dolphinrc####
###add###
[IconsMode]
PreviewSize=96

#####kdeglobals####
###add###
[PreviewSettings]
EnableRemoteFolderThumbnail=false
MaximumRemoteSize=10485760000


#####kwinrc####
###add###
[Effect-overview]
BorderActivate=2

[ElectricBorders]
BottomRight=ShowDesktop

[ScreenEdges]
RemainActiveOnFullscreen=true

#####kxkbrc####
###add###

[Layout]
LayoutList=pt
Use=true

kwinoutputconfig.json
##replace##
"scale": 2.25,

######kdeglobals - FULL FILE#####
applies theme

##kdedefaults > kdeglobals##
###replace
[General]
ColorScheme=BreezeDark

[Icons]
Theme=breeze-dark

###ksplashrc###
##replace##
Theme=org.kde.breezedark.desktop


#####SCREENLOCK####
##create kscreenlockerrc###

[Greeter][Wallpaper][org.kde.image][General]
Image=/home/ishmael/Downloads/cp2k77.jpeg
PreviewImage=/home/ishmael/Downloads/cp2k77.jpeg

###create###
##plasmarc##
[Wallpapers]
usersWallpapers=/home/ishmael/Downloads/cp2k77.jpeg

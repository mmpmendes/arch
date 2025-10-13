#!/bin/bash

#config variables
HOSTNAME='omega'
ROOT_PASSWORD=''
USER_NAME='ishmael'
USER_PASSWORD=''
TIMEZONE='Europe/Lisbon'
KEYMAP='pt-latin9'

##########################################################
###################### DRIVE SELECTION ######################
##########################################################

select_drive() {
  # Initialize empty variable to store drive paths
  DRIVE_PATHS=""
  # Get list of all block devices using lsblk, exclude header and loop devices
  DRIVES=$(lsblk -d -o PATH | grep -v '^PATH' | grep -v loop)

  # Check if any drives were found
  if [ -z "$DRIVES" ]; then
    echo "No drives found. Exiting."
    exit 1
  fi

  # Loop through each drive and append to DRIVE_PATHS
  while IFS= read -r drive; do
    DRIVE_PATHS="$DRIVE_PATHS $drive"
  done <<< "$DRIVES"

  # Remove leading/trailing whitespace
  DRIVE_PATHS=$(echo "$DRIVE_PATHS" | xargs)

  # Array of menu options
  options=($DRIVE_PATHS)
  # Current selected index
  selected=0
  # Total number of options
  total_options=${#options[@]}

  # Function to draw the menu
  draw_menu() {
    clear
    echo "###########################################"
    echo "#        Select installation drive        #"
    echo "###########################################"
    echo "#"
    for ((i=0; i<total_options; i++)); do
      if [ $i -eq $selected ]; then
        # Highlight selected option with > and background color
        echo -e "# > \033[7m${options[$i]}\033[0m "
      else
        echo "#   ${options[$i]}   "
      fi
    done
    echo "#"
    echo "###########################################"
    echo "#   Use ↑↓ to navigate, Enter to select   #"
    echo "###########################################"
  }

  # Save terminal settings and set to raw mode
  stty_orig=$(stty -g)
  stty -echo raw

  # Drive selection loop
  while true; do
    draw_menu
    # Read a single character
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      # Read the next two characters for arrow keys
      read -rsn2 -t 0.5 key 2>/dev/null
      case $key in
        '[A') # Up arrow
          ((selected--))
          if [ $selected -lt 0 ]; then
            selected=$((total_options-1))
          fi
          ;;
        '[B') # Down arrow
          ((selected++))
          if [ $selected -ge $total_options ]; then
            selected=0
          fi
          ;;
        *) # Ignore other escape sequences
          continue
          ;;
      esac
    elif [[ $key == "" ]]; then
      # Enter key pressed
      # Restore terminal settings before confirmation
      stty "$stty_orig"
      echo "Are you sure you want to use drive ${options[$selected]} to install Arch? ALL DATA WILL BE LOST!"
      echo "Press Enter to continue, Esc or any other key to cancel..."
      read -rsn1 confirm
      if [ -z "$confirm" ]; then
        # Enter was pressed, set DRIVE and proceed
        DRIVE="${options[$selected]}"
        # Validate drive
        if [ ! -b "$DRIVE" ]; then
          echo "Error: $DRIVE is not a valid block device."
          exit 1
        fi
        echo "Selected drive: $DRIVE"
        # Restore terminal settings before returning
        stty "$stty_orig"
        return 0 # Proceed with installation
      else
        # Any other key, return to menu
        stty -echo raw # Re-enable raw mode for menu
        continue
      fi
    fi
    # Other keys redraw the menu
  done
}

##########################################################
################### END DRIVE SELECTION #####################
##########################################################

setup() {

    echo '##### Drive selection #####'
    select_drive
    local installation_drive="$DRIVE"

    echo '##### Creating partitions #####'
    partition_drive "$installation_drive"

    echo '##### Formatting filesystems #####'
    format_filesystems "$installation_drive"

    echo '##### Mounting filesystems #####'
    mount_filesystems "$installation_drive"

    echo '##### Installing base system #####'
    install_base

    echo "##### Generating fstab #####"
    set_fstab

    echo '##### Chrooting into installed system #####'
    cp $0 /mnt/setup.sh
    arch-chroot /mnt ./setup.sh chroot



    reboot
}

configure() {
    echo '##### Installing additional packages #####'
    install_packages

    echo '##### Setting timezone #####'
    set_timezone "$TIMEZONE"

    echo '##### Setting locale #####'
    set_locale

    echo '##### Setting console keymap #####'
    set_keymap

    echo '##### Setting hostname #####'
    set_hostname "$HOSTNAME"

    echo '##### Configuring sudoers #####'
    set_sudoers

    if [ -z "$ROOT_PASSWORD" ]; then
        echo 'Enter the root password:'
        stty -echo
        read -p '' ROOT_PASSWORD
        stty echo
    fi
    echo '##### Setting root password #####'
    set_root_password "$ROOT_PASSWORD"

    if [ -z "$USER_PASSWORD" ]; then
        echo "Enter the password for user $USER_NAME"
        stty -echo
        read -p '' USER_PASSWORD
        stty echo
    fi
    echo '##### Creating initial user #####'
    create_user "$USER_NAME" "$USER_PASSWORD"

    echo '##### Enabling network manager #####'
    enable_network

    echo '##### Installing bootloader #####'
    install_grub

    rm /setup.sh
}

partition_drive() {
    local drive="$1"

    parted -s "$drive" \
        mklabel gpt \
        mkpart primary fat32 1MiB 513MiB \
        set 1 boot on \
        mkpart primary linux-swap 513MiB 8705MiB \
        mkpart primary btrfs 8705MiB 100%
}

format_filesystems() {
    local boot_partition="$1"p1;
    local swap_partition="$1"p2;
    local root_partition="$1"p3;

    mkfs.fat -F 32 -n boot "$boot_partition"
    mkfs.btrfs -f -L root "$root_partition"
    mkswap -L swap "$swap_partition"
}

mount_filesystems() {
    local boot_partition="$1"p1;
    local swap_partition="$1"p2;
    local root_partition="$1"p3;

    mount "$root_partition" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    umount /mnt

    mount -o subvol=@ "$root_partition" /mnt
    mkdir -p /mnt/home
    mount -o subvol=@home "$root_partition" /mnt/home
    mkdir /mnt/boot
    mount "$boot_partition" /mnt/boot
    swapon "$swap_partition"
}

install_base() {
    pacstrap -K /mnt base linux linux-firmware
}

install_packages() {
    local packages=''
    #General utilities/libraries
    packages+='grub efibootmgr btrfs-progs nano networkmanager sudo'
    pacman -Sy --noconfirm $packages
}

set_fstab() {
    genfstab -U /mnt >> /mnt/etc/fstab
}

set_timezone() {
    local timezone="$1"; shift

    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    hwclock --systohc
}

set_locale() {
    sed -i 's/#en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sed -i 's/#pt_PT\.UTF-8 UTF-8/pt_PT.UTF-8 UTF-8/' /etc/locale.gen

    echo 'LANG="pt_PT.UTF-8"' >> /etc/locale.conf
    echo 'LC_MESSAGES="en_US.UTF-8"' >> /etc/locale.conf
    locale-gen
}

set_keymap() {
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
}

set_hostname() {
    local hostname="$1"; shift
    echo "$hostname" > /etc/hostname
}

set_sudoers() {
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
}

set_root_password() {
    local password="$1"; shift

    echo -en "$password\n$password" | passwd
}

create_user() {
    local name="$1"; shift
    local password="$1"; shift
    
    useradd -m -G wheel -s /bin/bash "$name"
    echo -en "$password\n$password" | passwd "$name"
}

enable_network() {
    systemctl enable NetworkManager
}

install_grub(){
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
}

set -e

if [ "$1" == "chroot" ]
then
    configure
else
    setup
fi

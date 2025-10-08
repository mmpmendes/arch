#!/bin/bash

#config variables
DRIVE='/dev/sda'
HOSTNAME='omega'
ROOT_PASSWORD=''
USER_NAME='ishmael'
USER_PASSWORD=''
TIMEZONE='Europe/Lisbon'
KEYMAP='pt-latin9'

setup() {
    local drive="$DRIVE"

    echo '##### Creating partitions #####'
    partition_drive "$drive"

    echo '##### Formatting filesystems #####'
    format_filesystems "$drive"

    echo '##### Mounting filesystems #####'
    mount_filesystems "$drive"

    echo '##### Installing base system #####'
    install_base

    echo "##### Generating fstab #####"
    set_fstab

    echo '##### Chrooting into installed system #####'
    cp $0 /mnt/setup.sh
    arch-chroot /mnt ./setup.sh chroot

    if [ -f /mnt/setup.sh ]
    then
        echo 'ERROR: Something failed inside the chroot, not unmounting filesystems so you can investigate.'
        echo 'Make sure you unmount everything before you try to run this script again.'
    else
        echo 'Unmounting filesystems'
        echo 'Done! Reboot system.'
    fi

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

    if [ -z "$ROOT_PASSWORD" ]
    then
        echo 'Enter the root password:'
        stty -echo
        read ROOT_PASSWORD
        stty echo
    fi
    echo '##### Setting root password #####'
    set_root_password "$ROOT_PASSWORD"

    if [ -z "$USER_PASSWORD" ]
    then
        echo "Enter the password for user $USER_NAME"
        stty -echo
        read USER_PASSWORD
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
    local drive="$1";

    parted -s "$drive" \
        mklabel gpt \
        mkpart primary fat32 1MiB 513MiB \
        set 1 boot on \
        mkpart primary linux-swap 513MiB 4609MiB \
        mkpart primary btrfs 4609MiB 100%
}

format_filesystems() {
    local boot_partition="$1"1;
    local swap_partition="$1"2;
    local root_partition="$1"3;

    mkfs.fat -F 32 -n boot "$boot_partition"
    mkfs.btrfs -L root "$root_partition"
    mkswap -L swap "$swap_partition"
}

mount_filesystems() {
    local boot_partition="$1"1;
    local swap_partition="$1"2;
    local root_partition="$1"3;

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
    packages+='grub efibootmgr nano networkmanager sudo'
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

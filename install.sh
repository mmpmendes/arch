#!/bin/bash

# Drive to install to.
DRIVE='/dev/sda'

# Hostname of the installed machine.
HOSTNAME='omega'

# Root password (leave blank to be prompted).
ROOT_PASSWORD=''

# Main user to create (by default, added to wheel group, and others).
USER_NAME='ishmael'

# The main user's password (leave blank to be prompted).
USER_PASSWORD=''

# System timezone.
TIMEZONE='Europe/Lisbon'

KEYMAP='pt-latin9'

setup() {
    local drive="$DRIVE"

    echo 'Creating partitions'
    partition_drive "$drive"

    echo 'Formatting filesystems'
    format_filesystems "$drive"

    echo 'Mounting filesystems'
    mount_filesystems "$drive"

    echo "Listing available disks..."
    lsblk

    sleep 10
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
    local boot_partion="$1"1;
    local swap_parition="$1"2;
    local root_partion="$1"3;

    mkfs.fat -F 32 -L boot "$boot_partion"
    mkfs.btrfs -L root "$root_partion"
    mkswap "$swap_parition"
}

mount_filesystems() {
    local boot_partion="$1"1;
    local swap_parition="$1"2;
    local root_partion="$1"3;

    mount -o subvol=@ "$root_partion" /mnt
    mkdir -p /mnt/home
    mount -o subvol=@home "$root_partion" /mnt/home
    mkdir /mnt/boot
    mount "$boot_partion" /mnt/boot
    swapon "$swap_parition"
}


set -ex

if [ "$1" == "chroot" ]
then
    configure
else
    setup
fi

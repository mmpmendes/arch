#!/bin/bash
set -eo pipefail  # Fail fast: exit on error, pipe fail

# ── Configuration ─────────────────────────────────────────────────────
TIMEZONE='Europe/Lisbon'
KEYMAP='pt-latin9'

# ── Colors ───────────────────────────────────────────────────────────
BOLD='\e[1m' BGREEN='\e[92m' BYELLOW='\e[93m' BRED='\e[91m' RESET='\e[0m'

info_print() { printf "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] %b${RESET}\n" "$1"; }
warn_print() { printf "${BOLD}${BYELLOW}[ ${BRED}!${BYELLOW} ] %b${RESET}\n" "$1"; }

# ── Redirect stdin from TTY ──────────────────────────────────────────
exec < /dev/tty

# ── Drive Selection Menu ─────────────────────────────────────────────
select_drive() {
  mapfile -t options < <(lsblk -dno PATH | grep -v '^/dev/loop')
  (( ${#options[@]} )) || { info_print "No drives found."; exit 1; }

  local selected=0 total=${#options[@]}

  draw_menu() {
    clear
    info_print "###########################################"
    info_print "#    Select installation drive (Surface)  #"
    info_print "###########################################"
    info_print ""

    for ((i=0; i<total; i++)); do
      [[ $i -eq $selected ]] && \
        info_print "# > \033[7m${options[i]}\033[0m" || \
        info_print "#   ${options[i]}  "
    done

    info_print ""
    info_print "###########################################"
    info_print "#   ↑↓ to navigate, Enter to select       #"
    info_print "###########################################"
  }

  read_key() {
    local key
    read -rsn1 key
    [[ $key == $'\x1b' ]] && read -rsn2 -t 0.1 key && case $key in
      '[A') ((selected--)); (( selected < 0 )) && selected=$((total-1)) ;;
      '[B') ((selected++)); (( selected >= total )) && selected=0 ;;
    esac
    [[ -z $key ]] && return 0  # Enter pressed
    return 1
  }

  while :; do
    draw_menu
    read_key && break
  done

  DRIVE=${options[selected]}
  [[ -b $DRIVE ]] || { info_print "Invalid drive."; exit 1; }

  echo -e "\nUse $DRIVE? ALL DATA WILL BE ERASED!"
  read -rn1 -p "Press Enter to confirm, any other key to cancel... " confirm
  [[ -z $confirm ]] || exit 0
  info_print "Selected: $DRIVE"
  DRIVE_TYPE=$(get_drive_type "$DRIVE")
}

get_drive_type() { [[ $1 =~ /dev/nvme ]] && echo "nvme" || echo "sda"; }

# ── Partitioning ─────────────────────────────────────────────────────
partition_drive() {
  local drive=$1 suffix=$([[ $DRIVE_TYPE == nvme ]] && echo "p" || echo "")
  parted -s "$drive" mklabel gpt \
    mkpart primary fat32 1MiB 513MiB set 1 esp on \
    mkpart primary linux-swap 513MiB 8705MiB \
    mkpart primary btrfs 8705MiB 100%

  BOOT_PART="${drive}${suffix}1"
  SWAP_PART="${drive}${suffix}2"
  ROOT_PART="${drive}${suffix}3"
}

format_filesystems() {
  mkfs.fat -F32 -n BOOT "$BOOT_PART"
  mkfs.btrfs -f -L ROOT "$ROOT_PART"
  mkswap -L SWAP "$SWAP_PART"
}

mount_filesystems() {
  mount "$ROOT_PART" /mnt
  btrfs subvolume create /mnt/@ /mnt/@home
  umount /mnt

  mount -o subvol=@ "$ROOT_PART" /mnt
  mkdir -p /mnt/{boot,home}
  mount -o subvol=@home "$ROOT_PART" /mnt/home
  mount "$BOOT_PART" /mnt/boot
  swapon "$SWAP_PART"
}

# ── Setup (Outside Chroot) ───────────────────────────────────────────
setup() {
  read -p "Hostname: " HOSTNAME
  read -s -p "Root password: " ROOT_PASSWORD; echo
  read -p "Username: " USER_NAME
  read -s -p "User password: " USER_PASSWORD; echo

  select_drive

  info_print "Creating partitions..."
  partition_drive "$DRIVE"

  info_print "Formatting..."
  format_filesystems

  info_print "Mounting..."
  mount_filesystems

  info_print "Installing base system with Surface kernel..."
  # Install base system with linux-lts for better Surface compatibility
  pacstrap -K /mnt base linux-lts linux-lts-headers linux-firmware

  info_print "Generating fstab..."
  genfstab -U /mnt >> /mnt/etc/fstab

  info_print "Entering chroot..."
  cp "$0" /mnt/setup.sh
  arch-chroot /mnt env \
    HOSTNAME="$HOSTNAME" \
    ROOT_PASSWORD="$ROOT_PASSWORD" \
    USER_NAME="$USER_NAME" \
    USER_PASSWORD="$USER_PASSWORD" \
    /bin/bash /setup.sh chroot

  info_print "Rebooting in 5 seconds..."
  sleep 5 && reboot
}

# ── Configure (Inside Chroot) ────────────────────────────────────────
configure() {
  info_print "Installing essentials and Surface-specific packages..."
  # Basic system packages
  pacman -Sy --noconfirm grub efibootmgr btrfs-progs nano networkmanager sudo \
    iwd wpa_supplicant dhcpcd

  # Surface-specific packages for WiFi and hardware support
  info_print "Adding linux-surface repository..."
  
  # Add linux-surface repository key and repository
  curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | \
    pacman-key --add -
  pacman-key --finger 56C464BAAC421453
  pacman-key --lsign-key 56C464BAAC421453
  
  # Add repository to pacman.conf
  cat >> /etc/pacman.conf << 'EOF'

[linux-surface]
Server = https://pkg.surfacelinux.com/arch/
EOF
  
  # Update repositories and install Surface packages
  pacman -Sy
  
  info_print "Installing Surface kernel and firmware..."
  pacman -S --noconfirm linux-surface linux-surface-headers iptsd libwacom-surface
  
  # Surface-specific firmware and drivers
  info_print "Installing Surface firmware and drivers..."
  pacman -S --noconfirm surface-ipts-firmware surface-dtx-daemon

  # Input and touchscreen support
  info_print "Installing input and touch support..."
  pacman -S --noconfirm xf86-input-libinput libinput

  info_print "Setting timezone & locale..."
  ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
  hwclock --systohc
  sed -i '/^#.* UTF-8$/s/^#//' /etc/locale.gen
  locale-gen
  echo "LANG=pt_PT.UTF-8" > /etc/locale.conf
  echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

  info_print "Setting hostname & users..."
  echo "$HOSTNAME" > /etc/hostname
  echo -e "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd
  useradd -mG wheel -s /bin/bash "$USER_NAME"
  echo -e "$USER_PASSWORD\n$USER_PASSWORD" | passwd "$USER_NAME"
  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

  info_print "Installing GRUB with Surface optimizations..."
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  
  # Add Surface-specific kernel parameters
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/&" button.lid_init_state=open/' /etc/default/grub
  
  grub-mkconfig -o /boot/grub/grub.cfg

  info_print "Enabling services..."
  systemctl enable NetworkManager
  systemctl enable iptsd  # Surface touchscreen daemon
  systemctl enable surface-dtx-daemon  # Surface detach daemon

  # Enable iwd for better WiFi performance
  systemctl enable iwd

  # Configure NetworkManager to use iwd as WiFi backend
  mkdir -p /etc/NetworkManager/conf.d/
  cat > /etc/NetworkManager/conf.d/wifi_backend.conf << 'EOF'
[device]
wifi.backend=iwd
EOF

  info_print "Downloading Surface-optimized post-install script..."
  local url="https://raw.githubusercontent.com/macaricol/arch/refs/heads/main/surface_post.sh"
  local dest="/home/$USER_NAME/surface_post.sh"
  if curl -fsSL "$url" -o "$dest" 2>/dev/null; then
    chown "$USER_NAME:$USER_NAME" "$dest"
    chmod 755 "$dest"
    info_print "surface_post.sh ready at $dest"
    info_print "Run ~/surface_post.sh after reboot to install desktop environment"
  else
    warn_print "Failed to download surface_post.sh"
    info_print "You can manually download it from: $url"
  fi

  rm -f /setup.sh
}

# ── Main ─────────────────────────────────────────────────────────────
[[ $1 == chroot ]] && configure || setup
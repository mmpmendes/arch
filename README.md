# Project Overview

This repository contains scripts for an automated Arch Linux installation with a choice of Hyprland (default) or KDE Plasma as the desktop environment.

## Scripts

### install.sh

Handles drive selection, partitioning (GPT + btrfs), and base system installation. Runs from the Arch live ISO and re-invokes itself inside the chroot to complete locale, user, and bootloader setup. Copies `post_reboot.sh` to the new user's home directory before rebooting.

### post_reboot.sh

Run after the first reboot to install and configure the desktop environment. Set the `DESKTOP` variable at the top of the file to `hyprland` (default) or `kde` before running.

### test_sddm_theme.sh

Scratchpad for KDE/SDDM configuration snippets. Not a runnable script.

## Step-by-Step Usage

### Using install.sh

1. **Prerequisites**: Ensure you have an active internet connection and a backup of your data.
2. **Execution**: Boot the Arch live ISO, then run `bash install.sh`. Select the drive and follow the prompts.
3. **Installation**: The script installs the base system, configures the chroot, and reboots automatically.

### Using post_reboot.sh

1. **Post-Reboot**: Log in as your user. `install.sh` copies `post_reboot.sh` to your home directory automatically.
2. **Configure**: Open `~/post_reboot.sh` and set `DESKTOP='hyprland'` or `DESKTOP='kde'` at the top. Adjust `GPU_PACKAGES` if not on AMD hardware.
3. **Execution**: Run `bash ~/post_reboot.sh`. The script installs the desktop, GPU drivers, and applies configuration. SDDM starts at the end of the script.

### Hyprland keybindings (when DESKTOP=hyprland)

| Key | Action |
|-----|--------|
| Super + Return | Terminal |
| Super + D | App launcher |
| Super + Q | Close window |
| Super + F | Fullscreen |
| Super + 1–5 | Switch workspace |
| Super + Shift + 1–5 | Move window to workspace |
| Super + H/J/K/L | Focus direction |
| Print | Screenshot region to clipboard |

## Customization

Edit the `CONFIGURATION` block at the top of each script before running:

- **install.sh**: `TIMEZONE`, `KEYMAP`, `LOCALE`, `LOCALE_MESSAGES`
- **post_reboot.sh**: `DESKTOP`, `KBD_LAYOUT`, `GPU_PACKAGES`, `HYPR_TERMINAL`

## Warnings

- **Data Loss**: Running `install.sh` will format the selected drive.
- **AMD GPU**: `post_reboot.sh` installs AMD drivers by default (`vulkan-radeon`, `mesa`, etc.). Edit `GPU_PACKAGES` for NVIDIA or Intel hardware.
- **UEFI Required**: The bootloader is installed for UEFI systems only (`x86_64-efi` target).
- **Internet Required**: Both scripts download packages. An active connection is required throughout.

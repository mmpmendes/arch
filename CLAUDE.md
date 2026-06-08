# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Arch Linux automated installation toolkit — two sequentially-executed Bash scripts that take a machine from a live ISO all the way to a configured KDE Plasma desktop. It is opinionated toward AMD hardware (Ryzen CPU, Radeon GPU) and Portuguese locale/timezone settings.

## Execution Flow

Scripts must run in order:

1. **`install.sh`** — Run from the Arch live ISO. Partitions the disk, installs the base system, and configures the chroot environment. It re-invokes itself inside the chroot: `arch-chroot /mnt /mnt/install.sh chroot`.
2. **`post_reboot.sh`** — Run after the first reboot into the new system. Installs KDE Plasma, desktop applications, AMD GPU drivers, and applies system/theme configuration.

## Linting

There is no test framework. Use `shellcheck` to validate scripts:

```bash
shellcheck install.sh post_reboot.sh
```

## Key Architectural Decisions

### Two-phase chroot pattern in `install.sh`
The script detects whether it is running outside or inside the chroot via `if [ "$1" == "chroot" ]`. The pre-chroot phase handles disk operations and `pacstrap`; the chroot phase handles locale, users, bootloader, and sudoers. Any new configuration that requires the target system's environment must go in the chroot block.

### Partition layout (not easily changed)
- EFI: FAT32, 513 MiB
- Swap: 8 GiB
- Root: btrfs with subvolumes `@` (mounted at `/`) and `@home` (mounted at `/home`)

Btrfs subvolume names and mount options are referenced across `partition_drive()`, `format_filesystems()`, and `mount_filesystems()` — changes to subvolume names must be kept in sync across all three functions.

### NVMe vs. SATA partition naming
`install.sh` detects NVMe drives and appends `p` to the device name for partition suffixes (e.g., `/dev/nvme0n1p1` vs `/dev/sda1`). Any new partition references must preserve this conditional.

### Hardcoded locale/hardware values
The following are intentionally hardcoded for the target environment and should only be changed deliberately:
- Timezone: `Europe/Lisbon`
- Locale: `pt_PT.UTF-8` (primary), `en_US.UTF-8` (fallback)
- Console keymap: `pt-latin9`
- CPU microcode: `amd-ucode`
- GPU drivers: `mesa`, `vulkan-radeon`, `libva-mesa-driver`, `mesa-vdpau`

### SDDM theme installation
`post_reboot.sh` clones `sddm-astronaut-theme` from GitHub into `/usr/share/sddm/themes/` and writes the theme config to `/etc/sddm.conf`. The wallpaper path is derived from within that cloned directory — if the theme repo changes its internal structure, the wallpaper path will break.

## `test_sddm_theme.sh`

This file contains commented-out KDE/kwriteconfig snippets used for manual experimentation. It is not executable automation — treat it as a scratchpad for KDE configuration commands.

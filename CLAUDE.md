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

### GPU and CPU microcode detection
`post_reboot.sh` runs `detect_gpu()` at install time, which installs `pciutils` (via `--needed`), reads `lspci` output, and sets `$GPU_PACKAGES` accordingly — AMD gets `mesa`/`vulkan-radeon`, NVIDIA gets `nvidia`/`nvidia-utils`, Intel gets `mesa`/`vulkan-intel`. CPU microcode (`amd-ucode` or `intel-ucode`) is detected separately via `/proc/cpuinfo` and prepended to `$GPU_PACKAGES`. If no GPU is recognised, the install step is skipped with a warning.

### Desktop selection via `DESKTOP` variable
`post_reboot.sh` branches on `DESKTOP='hyprland'` (default) or `DESKTOP='kde'` at the top of the CONFIGURATION block. The two paths install entirely different package sets and write different config files. Common to both paths: SDDM display manager, AMD GPU drivers, Bluetooth, mpv, and the fast-boot GRUB settings.

### SDDM theme installation (KDE path only)
When `DESKTOP='kde'`, `post_reboot.sh` clones `sddm-astronaut-theme` from GitHub into `/usr/share/sddm/themes/`. The wallpaper path is derived from within that cloned directory — if the theme repo changes its internal structure, the wallpaper path will break.

### Hyprland config generation
When `DESKTOP='hyprland'`, `post_reboot.sh` writes `~/.config/hypr/hyprland.conf`, `hyprpaper.conf`, and `hyprlock.conf` using heredocs. The heredoc for `hyprland.conf` uses an unquoted `EOF` delimiter so that `$KBD_LAYOUT` and `$HYPR_TERMINAL` expand; Hyprland's own `$variable` syntax is escaped with `\$` to survive the bash expansion.

## `test_sddm_theme.sh`

This file contains commented-out KDE/kwriteconfig snippets used for manual experimentation. It is not executable automation — treat it as a scratchpad for KDE configuration commands.

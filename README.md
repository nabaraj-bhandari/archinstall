# archinstall

Minimal Arch + Hyprland. One script. No bloat.

## Usage

```bash
# 1. Boot Arch ISO, connect internet (iwctl), partition disk:
cfdisk /dev/nvme0n1   # p1 = 512M EFI, p2 = rest Linux

# 2. Clone & run
git clone https://github.com/nabaraj-bhandari/archinstall
cd archinstall && chmod +x install.sh && ./install.sh
```

Reboots → ly login manager → login → Hyprland starts.  
Phase 2 (desktop setup) runs automatically once via systemd on first boot.

---

## Repo structure

```
install.sh                  ← single entry point
scripts/
  constants.sh              ← hostname, user, apps — edit this
  lib.sh                    ← shared helpers
  phase1.sh                 ← base install (from ISO)
  phase2.sh                 ← desktop install (after reboot)
  wallpaper.sh              ← wallpaper picker (yazi)
  wallpaper-init.sh         ← restore last wall on login
config/
  hypr/hyprland.conf
  kitty/kitty.conf
  waybar/config
  waybar/style.css
  tofi/config
  yazi/                     ← add yazi config here
  nvim/                     ← add nvim config here
  wal/templates/            ← pywal color templates
wallpapers/
  default.png               ← drop wallpapers here
```

## Keybinds

| Key | Action |
|---|---|
| SUPER + Enter | kitty |
| SUPER + A | tofi launcher |
| SUPER + W | wallpaper picker (yazi) |
| SUPER + D | yazi file manager |
| SUPER + Q | close window |
| SUPER + F | fullscreen |
| SUPER + V | float |
| SUPER + hjkl | move focus |
| SUPER + SHIFT + hjkl | move window |
| SUPER + ALT + hjkl | resize |
| SUPER + 1-5 | switch workspace |
| SUPER + SHIFT + 1-5 | move to workspace |
| Print | screenshot → clipboard |

## Wallpaper

Drop images into `~/.wallpapers/` then `SUPER+W` to pick.  
pywal regenerates colors across kitty, waybar, tofi, hyprland borders instantly.

## Customise

- Add apps: edit `scripts/constants.sh` → `EXTRA_PACKAGES`
- Change hostname/user: edit `scripts/constants.sh`
- Per-app config: edit files in `config/<app>/`

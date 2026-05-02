#!/usr/bin/env bash
# phase2.sh — installs hyprland, dots, services. runs once after reboot via systemd.

set -e

REPO_DIR="/root/archinstall"
source "$REPO_DIR/scripts/lib.sh"
source "$REPO_DIR/scripts/constants.sh"

info "Phase 2 — Hyprland + desktop setup"

# ── pacman packages ──────────────────────────────────────────────────────────
info "Installing packages..."
sudo pacman -Syu --noconfirm --needed \
    hyprland xdg-desktop-portal-hyprland \
    waybar \
    kitty \
    awww \
    python-pywal \
    grim slurp wl-clipboard \
    pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol \
    bluez bluez-utils bluetui \
    mesa vulkan-intel intel-media-driver \
    yazi openssh \
    neovim \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    polkit-gnome \
    brightnessctl playerctl \
    "${EXTRA_PACKAGES[@]}"

ok "Packages installed."

# ── dirs ─────────────────────────────────────────────────────────────────────
mkdir -p \
    ~/.config/hypr \
    ~/.config/kitty \
    ~/.config/waybar \
    ~/.config/tofi \
    ~/.config/yazi \
    ~/.config/nvim \
    ~/.config/wal/templates \
    ~/.wallpapers \
    ~/.local/bin

# ── copy configs ─────────────────────────────────────────────────────────────
info "Deploying configs..."

cp -r "$REPO_DIR"/config/hypr/* ~/.config/hypr/
cp -r "$REPO_DIR"/config/kitty/* ~/.config/kitty/
cp -r "$REPO_DIR"/config/waybar/* ~/.config/waybar/
cp -r "$REPO_DIR"/config/tofi/* ~/.config/tofi/
cp -r "$REPO_DIR"/config/yazi/* ~/.config/yazi/ 2>/dev/null || true
cp -r "$REPO_DIR"/config/nvim/* ~/.config/nvim/ 2>/dev/null || true

sed -i "s|/home/USER/|$HOME/|g" ~/.config/waybar/style.css ~/.config/tofi/config

# ── pywal templates ──────────────────────────────────────────────────────────
cp -r "$REPO_DIR"/config/wal/templates/* ~/.config/wal/templates/

# ── scripts ──────────────────────────────────────────────────────────────────
cp "$REPO_DIR"/scripts/wallpaper.sh ~/.local/bin/wallpaper
cp "$REPO_DIR"/scripts/wallpaper-init.sh ~/.local/bin/wallpaper-init
chmod +x ~/.local/bin/wallpaper ~/.local/bin/wallpaper-init

# ── default wallpaper ────────────────────────────────────────────────────────
if [ -f "$REPO_DIR/wallpapers/default.png" ]; then
    cp "$REPO_DIR/wallpapers/default.png" ~/.wallpapers/default.png
fi

# ── path ─────────────────────────────────────────────────────────────────────
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc ||
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc

# ── image magick update ──────────────────────────────────────────────────────
grep -qxF 'alias convert="magick"' ~/.bashrc ||
    echo 'alias convert="magick"' >>~/.bashrc

# ── services ─────────────────────────────────────────────────────────────────
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now bluetooth

# ── disable this oneshot so it never runs again ──────────────────────────────
sudo systemctl disable arch-phase2

ok "Phase 2 complete. Reboot → ly → login → Hyprland starts automatically."

#!/usr/bin/env bash
set -e

info() { echo -e "\e[32m[+]\e[0m $*"; }
die() {
    echo -e "\e[31m[x]\e[0m $*"
    exit 1
}

[ -d /sys/firmware/efi ] || die "Not UEFI."

lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
echo ""
read -rp "EFI partition: " EFI_PART
read -rp "Root partition: " ROOT_PART
read -rp "Username: " USERNAME
read -rsp "User password: " USER_PASS
echo
read -rsp "Root password: " ROOT_PASS
echo
read -rp "Hostname: " HOSTNAME

info "Formatting..."
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"

info "Mounting..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

pacman -Sy git --noconfirm

info "Installing packages..."
pacstrap -K /mnt \
    base base-devel linux linux-firmware intel-ucode \
    networkmanager \
    sway swaybg swayidle foot fuzzel mako waybar \
    grim slurp wl-clipboard xdg-desktop-portal-wlr xdg-user-dirs \
    pipewire wireplumber pipewire-pulse pipewire-alsa alsa-utils pavucontrol \
    brightnessctl playerctl \
    power-profiles-daemon \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-font-awesome \
    tmux neovim git fzf jq \
    yazi ffmpegthumbnailer imagemagick poppler \
    udiskie udisks2 \
    zip unzip p7zip unrar \
    firefox mpv imv \
    docker docker-compose kubectl terraform ansible \
    htop rsync curl wget \
    man-db man-pages \
    mesa vulkan-intel intel-media-driver \
    libva-intel-driver libva-utils \
    thermald lm_sensors \
    fortune-mod gdu s-tui yad \
    sudo

genfstab -U /mnt >>/mnt/etc/fstab

arch-chroot /mnt /bin/bash <<CHROOT
set -e

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
hwclock --systohc

echo "$HOSTNAME" > /etc/hostname
cat >> /etc/hosts << EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOF

echo "root:$ROOT_PASS" | chpasswd
useradd -m -G wheel,video,input,audio,storage,docker -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASS" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

bootctl install
cat > /boot/loader/loader.conf << EOF
default arch.conf
timeout 0
editor no
EOF

ROOT_UUID=\$(blkid -s UUID -o value $ROOT_PART)
cat > /boot/loader/entries/arch.conf << EOF
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=UUID=\$ROOT_UUID rw quiet loglevel=3
EOF

systemctl enable NetworkManager docker thermald power-profiles-daemon udisks2

CHROOT

H="/mnt/home/$USERNAME"

mkdir -p "$H/.config/sway"
cp /mnt/etc/sway/config "$H/.config/sway/config"

cat >>"$H/.config/sway/config" <<'EOF'

set $mod Mod4

bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

exec pipewire &
exec pipewire-pulse &
exec wireplumber &
exec mako &
exec udiskie &
exec waybar &
exec swayidle -w timeout 300 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"'

output * scale 2
output * bg ~/wallpaper.jpg fill
EOF

mkdir -p "$H/.config/waybar"

cat >"$H/.config/waybar/config" <<'EOF'
{
  "layer": "top",
  "position": "top",
  "height": 30,
  "modules-left": ["sway/workspaces", "sway/window"],
  "modules-center": ["custom/player"],
  "modules-right": ["pulseaudio","backlight","network","cpu","memory","temperature","battery","tray","clock"],

  "sway/window": {
    "max-length": 60
  },

  "custom/player": {
    "exec": "playerctl -a metadata --format '{{artist}} - {{title}}' -F",
    "return-type": "text",
    "max-length": 40,
    "on-click": "playerctl play-pause",
    "on-click-right": "playerctl next"
  },

  "clock": {
    "format": "{:%H:%M}"
  },

  "cpu": {
    "format": "󰘚 {usage}%"
  },

  "memory": {
    "format": "󰍛 {}%"
  },

  "temperature": {
    "format": "{temperatureC}°C"
  },

  "battery": {
    "format": "{capacity}%"
  },

  "network": {
    "format-wifi": "󰖩 {signalStrength}%",
    "format-ethernet": "󰈀",
    "format-disconnected": "󰖪"
  },

  "pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": "󰝟",
    "format-icons": {
      "default": ["󰕿","󰖀","󰕾"]
    },
    "on-click": "pavucontrol",
    "on-scroll-up": "pactl set-sink-volume @DEFAULT_SINK@ +2%",
    "on-scroll-down": "pactl set-sink-volume @DEFAULT_SINK@ -2%"
  },

  "backlight": {
    "format": "{percent}%"
  },

  "tray": {
    "spacing": 5
  }
}
EOF

cat >"$H/.config/waybar/style.css" <<'EOF'
* {
  font-family: JetBrainsMono Nerd Font;
  font-size: 13px;
}

window#waybar {
  background: rgba(10,10,12,0.8);
  color: #d8dee9;
}

#workspaces button.active {
  color: #88c0d0;
}

#pulseaudio, #network, #cpu, #memory, #battery, #clock {
  padding: 0 10px;
}
EOF

git clone https://github.com/LazyVim/starter "$H/.config/nvim"
rm -rf "$H/.config/nvim/.git"

curl -sL https://raw.githubusercontent.com/nabaraj-bhandari/archsetup/main/wallpaper.jpg -o "$H/wallpaper.jpg"

mkdir -p "$H/Pictures" "$H/Downloads" "$H/Projects"

arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

umount -R /mnt
info "Done. Reboot."

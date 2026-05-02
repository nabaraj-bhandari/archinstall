#!/usr/bin/env bash
# phase1.sh — runs from Arch ISO:
# partition, pacstrap, bootloader, schedule phase2

[ -d /sys/firmware/efi ] || die "Not UEFI."
ping -c 1 archlinux.org &>/dev/null || die "No internet. Connect with iwctl first."

echo -e "\n${C}=== ARCH INSTALL — phase 1 ===${N}\n"

# ── disk ────────────────────────────────────────────────────────────────────
lsblk -o NAME,SIZE,TYPE
echo ""

if [ -z "$EFI_PART" ]; then
    read -rp "EFI partition  (e.g. /dev/nvme0n1p1): " EFI_PART
fi
if [ -z "$ROOT_PART" ]; then
    read -rp "Root partition (e.g. /dev/nvme0n1p2): " ROOT_PART
fi

# ── credentials ─────────────────────────────────────────────────────────────
read -rsp "Password for $USERNAME: " USER_PASSWORD
echo
read -rsp "Root password: " ROOT_PASSWORD
echo

# ── cpu ─────────────────────────────────────────────────────────────────────
if [ -z "$CPU" ]; then
    read -rp "CPU [intel/amd]: " CPU
fi
CPU=$(echo "$CPU" | tr '[:upper:]' '[:lower:]')
[[ "$CPU" == "amd" ]] && UCODE="amd-ucode" || UCODE="intel-ucode"

# ── confirm ─────────────────────────────────────────────────────────────────
echo ""
warn "WIPE: $EFI_PART (FAT32) + $ROOT_PART (ext4)"
read -rp "Continue? [y/N]: " GO
[[ "$GO" =~ ^[Yy]$ ]] || die "Aborted."

# ── format & mount ──────────────────────────────────────────────────────────
info "Formatting..."
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"

info "Mounting..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

# ── pacstrap ─────────────────────────────────────────────────────────────────
info "Pacstrapping base..."
pacstrap -K /mnt \
    base base-devel linux linux-firmware \
    "$UCODE" networkmanager git vim sudo ly

genfstab -U /mnt >>/mnt/etc/fstab
ok "fstab written."

# ── copy repo into new system ────────────────────────────────────────────────
info "Copying install repo to new system..."
cp -r "$REPO_DIR" /mnt/root/archinstall

# ── chroot ───────────────────────────────────────────────────────────────────
info "Configuring system in chroot..."

arch-chroot /mnt /bin/bash <<CHROOT
set -e

# time & locale
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# hostname
echo "$HOSTNAME" > /etc/hostname
cat >> /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# users
echo "root:$ROOT_PASSWORD" | chpasswd
useradd -m -G wheel,audio,video,storage,input -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# bootloader
bootctl install
cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 0
editor no
EOF
ROOT_UUID=\$(blkid -s UUID -o value $ROOT_PART)
cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /$UCODE.img
initrd  /initramfs-linux.img
options root=UUID=\$ROOT_UUID rw quiet loglevel=3
EOF

# services
systemctl enable NetworkManager
systemctl enable ly

# ── phase2 oneshot service ───────────────────────────────────────────────────
# runs phase2.sh as $USERNAME on first login session
cat > /etc/systemd/system/arch-phase2.service <<EOF
[Unit]
Description=Arch install phase 2
After=network-online.target
Wants=network-online.target
ConditionPathExists=/root/archinstall/scripts/phase2.sh

[Service]
Type=oneshot
User=$USERNAME
WorkingDirectory=/root/archinstall
ExecStart=/bin/bash /root/archinstall/install.sh --phase2
StandardOutput=journal+console
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable arch-phase2

CHROOT

ok "Phase 1 complete."
echo ""
warn "Unmounting..."
umount -R /mnt
echo ""
read -rp "Reboot now? [y/N]: " RB
[[ "$RB" =~ ^[Yy]$ ]] && reboot || echo "Run 'reboot' when ready."

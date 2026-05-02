#!/usr/bin/env bash
# phase1.sh — runs from Arch ISO:
# partition, pacstrap, bootloader, schedule phase2

[ -d /sys/firmware/efi ] || die "Not UEFI."
ping -c 1 archlinux.org &>/dev/null || die "No internet. Connect with iwctl first."

echo -e "\n=== ARCH INSTALL — phase 1 ===\n"

# disk setup
lsblk -o NAME,SIZE,TYPE
echo ""

[ -z "$EFI_PART" ] && read -rp "EFI partition (e.g. /dev/nvme0n1p1): " EFI_PART
[ -z "$ROOT_PART" ] && read -rp "Root partition (e.g. /dev/nvme0n1p2): " ROOT_PART

# credentials
read -rsp "Password for $USERNAME: " USER_PASSWORD
echo
read -rsp "Root password: " ROOT_PASSWORD
echo

# cpu ucode
[ -z "$CPU" ] && read -rp "CPU [intel/amd]: " CPU
CPU=$(echo "$CPU" | tr '[:upper:]' '[:lower:]')
[[ "$CPU" == "amd" ]] && UCODE="amd-ucode" || UCODE="intel-ucode"

echo ""
warn "WIPE: $EFI_PART (FAT32) + $ROOT_PART (ext4)"
read -rp "Continue? [y/N]: " GO
[[ "$GO" =~ ^[Yy]$ ]] || die "Aborted."

info "Formatting & Mounting..."
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount -o fmask=0077,dmask=0077 "$EFI_PART" /mnt/boot

info "Pacstrapping base..."
pacstrap -K /mnt base base-devel linux linux-firmware "$UCODE" networkmanager git vim sudo ly
genfstab -U /mnt >>/mnt/etc/fstab

info "Copying repo..."
cp -r "$REPO_DIR" /mnt/root/archinstall

info "Chroot configuration..."
arch-chroot /mnt /bin/bash <<CHROOT
set -e
pacman -Sy --noconfirm networkmanager ly

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname

cat >> /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

echo "root:$ROOT_PASSWORD" | chpasswd
useradd -m -G wheel,audio,video,storage,input -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

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

systemctl enable NetworkManager.service
systemctl enable ly.service
systemctl enable arch-phase2.service

CHROOT

ok "Phase 1 complete."
warn "Unmounting..."
umount -R /mnt
read -rp "Reboot now? [y/N]: " RB
[[ "$RB" =~ ^[Yy]$ ]] && reboot

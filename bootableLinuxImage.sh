#!/bin/bash
set -e
LOOP_DEVICE=""
cleanup() {
    if [ -n "$LOOP_DEVICE" ]; then
        sudo losetup -d "$LOOP_DEVICE" || true
    fi
    if [ -d "mnt" ]; then
        sudo umount -l "mnt" || true
        rmdir "mnt" || true
    fi
}
trap cleanup EXIT

# Set up and mount the image and filesystem
dd if=/dev/zero of="linux_image.img" bs=1G count=1
mkfs.ext4 "linux_image.img"
mkdir -p "mnt"
LOOP_DEVICE=$(sudo losetup --find --show "linux_image.img")
sudo mount "$LOOP_DEVICE" "mnt"

# Set up Ubuntu 4.4.0 because every other version I downloaded gave me a kernel panic
sudo debootstrap --arch amd64 focal "mnt" "http://security.ubuntu.com/ubuntu"
mkdir -p "kernel_files"
wget "http://security.ubuntu.com/ubuntu/pool/main/l/linux/linux-image-4.4.0-142-generic_4.4.0-142.168_amd64.deb" -O "kernel_files/linux-image-4.4.0-142-generic_4.4.0-142.168_amd64.deb"
dpkg-deb -x "kernel_files/linux-image-4.4.0-142-generic_4.4.0-142.168_amd64.deb" "kernel_files"
sudo cp -r "kernel_files/lib" "mnt/lib"
sudo chown -R $USER:$USER "kernel_files"

# Complete tasks once the filesystem has booted
sudo chroot "mnt" /bin/bash <<EOF
apt-get update
# Use busybox because I kept getting kernel panics
apt-get install -y busybox-static
mkdir -p /etc/init.d
cat <<'EOL' > /etc/init.d/rcS
#!/bin/sh
sleep 5
echo "Hello, World!" > /dev/console
exit
EOL

chmod +x /etc/init.d/rcS

ln -s /bin/busybox /init
exit
EOF


cleanup

# Boot it
qemu-system-x86_64 \
    -drive file="linux_image.img",format=raw \
    -m 512M \
    -kernel "kernel_files/boot/vmlinuz-4.4.0-142-generic" \
    -append "root=/dev/sda rw console=ttyS0 init=/init debug" \
    -serial mon:stdio \
    -nographic
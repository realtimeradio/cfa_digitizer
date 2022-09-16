follow build instructions from https://forum.digikey.com/t/debian-getting-started-with-the-beaglebone-black/12967

# Get ARM Cross Compiler

```
wget -c https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/11.1.0/x86_64-gcc-11.1.0-nolibc-arm-linux-gnueabi.tar.xz
tar -xf x86_64-gcc-11.1.0-nolibc-arm-linux-gnueabi.tar.xz
export CC=`pwd`/gcc-11.1.0-nolibc/arm-linux-gnueabi/bin/arm-linux-gnueabi-
```

# Get U-boot

If you want, you can skip this step and just use the submoduled u-boot

```
git clone -b v2022.04 https://github.com/u-boot/u-boot --depth=1
cd u-boot/
git pull --no-edit https://git.beagleboard.org/beagleboard/u-boot.git v2022.04-bbb.io-am335x-am57xx
```

## Modify U-boot to boot even if SIPP is not a beaglebone.

In `board/ti/am335x/board.h` modify `board_is_bone_lt(void)` to always return 1.

# Build U-BOOT

Build U-boot (from within `u-boot` directory):

```
make ARCH=arm CROSS_COMPILE=${CC} distclean
make ARCH=arm CROSS_COMPILE=${CC} am335x_evm_defconfig
make ARCH=arm CROSS_COMPILE=${CC}
```

# Get Linux kernel / build scripts

You can skip this step if using the submoduled `bb-kernel`

```
git clone https://github.com/RobertCNelson/bb-kernel ./kernelbuildscripts
cd kernelbuildscripts/
git checkout origin/am33x-rt-v5.15
```

# Build Linux kernel

First run a kernel build without any custom configuration, which will pull the linux source
```
./build_kernel.sh
```

Once linux has been downloaded to `KERNEL`, add the new device tree

```
cp am335x-osd3358-sm-adze.dtb KERNEL/arch/arm/boot/dts/
```

Update Makefile so that this device tree is actually built to dtb

```
diff --git a/arch/arm/boot/dts/Makefile b/arch/arm/boot/dts/Makefile
index 05d8aef6e5d2..16f016943f42 100644
--- a/arch/arm/boot/dts/Makefile
+++ b/arch/arm/boot/dts/Makefile
@@ -956,6 +956,7 @@ dtb-$(CONFIG_SOC_AM33XX) += \
        am335x-sbc-t335.dtb \
        am335x-sl50.dtb \
        am335x-wega-rdk.dtb \
+       am335x-osd3358-sm-adze.dtb \
        am335x-osd3358-sm-red.dtb
 dtb-$(CONFIG_ARCH_OMAP4) += \
        omap4-droid-bionic-xt875.dtb \
```

Copy custom linux config (which enables drivers for MARVELL PHY, etc.)

```
cp .config KERNEL/.config
```

Rebuild:

```
tools/rebuild.sh
```

## Make SD Card
I followed the guide and made a card with a single ext4 partition (rather than the usual FAT32 boot + ext root)

```
export DISK=/dev/sdb # or mmcblkX or whatever. 

#Erase partition table/labels on microSD card:

sudo dd if=/dev/zero of=${DISK} bs=1M count=10

#Install Bootloader:
sudo dd if=./u-boot/MLO of=${DISK} count=2 seek=1 bs=128k
sudo dd if=./u-boot/u-boot-dtb.img of=${DISK} count=4 seek=1 bs=384k

#Create Partition Layout:
#Check the version of sfdisk installed on your pc is atleast 2.26.x or newer.
sudo sfdisk --version

#sfdisk >= 2.26.x
sudo sfdisk ${DISK} <<-__EOF__
4M,,L,*
__EOF__

#Format Partition:
#With mkfs.ext4 1.43, we need to make sure metadata_csum and 64bit ext4 features are disabled.
#As the version of U-Boot needed for this target CAN NOT correctly handle reading files with these newer ext4 options.

mkfs.ext4 -V

#mkfs.ext4 >= 1.43
#for: DISK=/dev/sdX If DISK=/dev/mmcblkX then the final arg should be ${DISK}p1
sudo mkfs.ext4 -L rootfs -O ^metadata_csum,^64bit ${DISK}1
```

# Build the ROOTFS

Following MB's instructions

```
jackh@rtr-dev1:~/src/sparrow-fpga/linux/sparrow-linux$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 18.04.4 LTS
Release:	18.04
Codename:	bionic
```

Mount ext4 partition of SD card and as root

```
export ROOTFS=/mnt/rootfs
mount /dev/sdd2 $ROOTFS # or whatever
cd $ROOTFS

export UBUNTU_ARM64=http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.5-base-arm64.tar.gz
export UBUNTU_ARM32=http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.5-base-armhf.tar.gz
export QEMU_64=qemu-aarch64-static
export QEMU_32=qemu-arm-static

export QEMU=$QEMU_32
export UBUNTU=$UBUNTU_ARM32
```

```
apt install -y qemu-user-static
wget $UBUNTU
tar -xzf ubuntu*.tar.gz

cp -av /usr/bin/$QEMU $ROOTFS/usr/bin/
# Give network access when in chroot, so we can download packages
cp -av /run/systemd/resolve/stub-resolv.conf $ROOTFS/etc/resolv.conf

mount --bind /dev/ $ROOTFS/dev
mount --bind /proc/ $ROOTFS/proc
mount --bind /sys/ $ROOTFS/sys
chroot $ROOTFS
```

Stop here and run uname -a to check we're actually in a chroot using qemu

```
# make casper user. Password casper
useradd -G sudo -m -s /bin/bash casper
echo casper:casper | chpasswd

apt update
apt upgrade -y

# Install first, as needed for other package installs
apt install -y locales
apt install -y dialog perl

apt install -y sudo apt-utils vim

apt install -y ifupdown net-tools ethtool udev iputils-ping resolvconf wget kmod device-tree-compiler openssh-client openssh-server build-essential cmake git

echo "# <file system> <dir> <type> <options> <dump> <pass>" > /etc/fstab
echo "/dev/mmcblk0p1 /boot  vfat   umask=0002,utf8=true  0 0" >> /etc/fstab

mkdir -p /etc/network/interfaces.d
echo "auto eth0" > /etc/network/interfaces.d/eth0
echo "iface eth0 inet dhcp" >> /etc/network/interfaces.d/eth0

# exit the chroot
exit

umount $ROOTFS/dev
umount $ROOTFS/proc
umount $ROOTFS/sys

cd ~
umount $ROOTFS
```

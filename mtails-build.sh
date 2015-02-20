#!/bin/bash

# Martus M-Tails Builder Script
# by Nicholas Merrill nick@calyx.com
#
# Copyright (c) 2015 Benetech
#

if [[ "$1" == "clean" ]]; then
	sudo rm -rf /tmp/mtails-iso /tmp/working
	echo -e "\n\nCleaned up the downloaded packages and other working files."
	echo -e "You can now re-run the script with:"
	echo -e "$0"
	exit 0
elif [[ "$1" == "distclean" ]]; then
	sudo rm -rf /tmp/mtails-iso /tmp/tails-iso /tmp/working
	echo -e "\n\nCleaned up the doanloaded packages, Tails 1.2.3. ISO image, and other working files."
	echo -e "You can now re-run the script with:"
	echo -e "$0"
	exit 0
else
	echo -e "M-Tails build script (c) 2015 Benetech\n\n"
fi

TAILS_ISO_URL="http://dl.amnesia.boum.org/tails/stable/tails-i386-1.2.3/tails-i386-1.2.3.iso"
TAILS_SIG_URL="https://tails.boum.org/torrents/files/tails-i386-1.2.3.iso.sig"
TAILS_KEY_URL="https://tails.boum.org/tails-signing.key"

#check if script is running as root, if it is then exit
if [[ "$(id -u)" = "0" ]]; then
	echo -e  "This script should not be run as root.  Please run as an unprivileged user."
	exit 1
fi

echo -e "installing local prerequisites"
sudo apt-get install curl wget squashfs-tools

# create needed directories
echo -e  "Creating working directories...\n\n"
mkdir -p "/tmp/tails-iso"
mkdir -p "/tmp/tails-iso/mnt"
mkdir -p "/tmp/working"
cp chroot-tasks.sh martus-documentation.tgz *.desktop *.png martus-documentation /tmp/working/

# get the tails.iso if it isn't already there
echo -e "Checking if we already have the latest Tails ISO."

if [[ -f "/tmp/tails-iso/tails-i386-1.2.3.iso" ]]; then
	echo -e  "Tails ISO already exists.  Good."
fi

if [[ ! -f "/tmp/tails-iso/tails-i386-1.2.3.iso" ]]; then
	echo -e  "We don't have it yet.  Retrieving Tails ISO image\n\n"
	cd /tmp/tails-iso
	wget --progress=bar "http://dl.amnesia.boum.org/tails/stable/tails-i386-1.2.3/tails-i386-1.2.3.iso"
	cd ..
fi

# verify the tails iso
echo -e  "\n\nVerifying the authenticity of the Tails ISO image using GPG signatures..."
if [[ ! -f "/tmp/tails-iso/tails-signing-key" ]]; then
	curl -o /tmp/tails-iso/tails-signing.key $TAILS_KEY_URL
fi
if [[ ! -f "/tmp/tails-iso/tails-iso.sig" ]]; then
	curl -o /tmp/tails-iso/tails-iso.sig $TAILS_SIG_URL
fi

rm -f /tmp/working/tmp_keyring.pgp
gpg -q --no-default-keyring --keyring /tmp/working/tmp_keyring.pgp --import /tmp/tails-iso/tails-signing.key

if gpg --no-default-keyring --keyring /tmp/working/tmp_keyring.pgp --fingerprint BE2CD9C1 | grep "0D24 B36A A9A2 A651 7878  7645 1202 821C BE2C D9C1"; then
	echo -e  "Tails developer key verified..."
else
	echo -e  "ERROR.  Tails developer key does not seem to be the right one.  Something strange is going on.  Exiting."
	exit 1
fi

echo -e "\n\nNow verifying that the signature on the Tails ISO matches the Tails developer key..."

if gpg -q --no-default-keyring --keyring /tmp/working/tmp_keyring.pgp --keyid-format long --verify /tmp/tails-iso/tails-iso.sig /tmp/tails-iso/tails-i386-1.2.3.iso; then
	echo -e  "Tails ISO signed by the Tails developer key and seems legitimate.  Proceeding."
else
	echo -e  "ERROR.  The Tails ISO does not seem to be signed by the proper signing key.  Something strange is going on.  Exiting."
	exit 1
fi

# mount the ISO image
echo -e  "\n\nMounting Tails ISO image.  You may need to enter your password."
sudo mount -o loop /tmp/tails-iso/tails-i386-1.2.3.iso /tmp/tails-iso/mnt

# extract the squashed filesystem
echo -e  "\n\nExtracting the compressed root filesystem from the Tails ISO image"
sudo cp /tmp/tails-iso/mnt/live/filesystem.squashfs /tmp/working

# decompress the squashed filesystem
if [[ -f "/tmp/working/squashfs-root" ]]; then
	echo -e  "\n\nSquashed filesystem already uncompressed.  Good."
fi

if [[ ! -f "/tmp/working/squashfs-root" ]]; then
	echo -e  "\n\nDecompressing the compressed root filesystem...  You may need to enter your password again."
	cd /tmp/working
	sudo unsquashfs filesystem.squashfs
fi

# download packages
echo -e  "\n\nDownloading Martus and its dependencies..."
if [[ ! -f "/tmp/working/libnss3_3.17.2-1.1_i386.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/n/nss/libnss3_3.17.2-1.1_i386.deb"
fi
if [[ ! -f "/tmp/working/libjpeg62-turbo_1.3.1-11_i386.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.3.1-11_i386.deb"
fi
if [[ ! -f "/tmp/working/openjdk-8-jre-headless_8u40~b22-2_i386.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/o/openjdk-8/openjdk-8-jre-headless_8u40~b22-2_i386.deb"
fi
if [[ ! -f "/tmp/working/openjdk-8-jre_8u40~b22-2_i386.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/o/openjdk-8/openjdk-8-jre_8u40~b22-2_i386.deb"
fi
if [[ ! -f "/tmp/working/openjdk-8-jdk_8u40~b22-2_i386.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/o/openjdk-8/openjdk-8-jdk_8u40~b22-2_i386.deb"
fi
if [[ ! -f "/tmp/working/openjfx_8u20-b26-3_i386.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/o/openjfx/openjfx_8u20-b26-3_i386.deb"
fi
if [[ ! -f "/tmp/working/libopenjfx-java_8u20-b26-3_all.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/o/openjfx/libopenjfx-java_8u20-b26-3_all.deb"
fi
if [[ ! -f "/tmp/working/libopenjfx-jni_8u20-b26-3_i386.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/o/openjfx/libopenjfx-jni_8u20-b26-3_i386.deb"
fi
if [[ ! -f "/tmp/working/libicu4j-java_4.4.2.2-2_all.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/i/icu4j-4.4/libicu4j-4.4-java_4.4.2.2-2_all.deb"
fi
if [[ ! -f "/tmp/working/tzdata-java_2015a-1_all.deb" ]]; then
	wget --progress=bar "http://ftp.us.debian.org/debian/pool/main/t/tzdata/tzdata-java_2015a-1_all.deb"
fi
if [[ ! -f "/tmp/working/Martus-5.0.2.zip" ]]; then
	wget --progress=bar "https://martus.org/installers/Martus-5.0.2.zip"
fi

# copy packages into /tmp directory of squashfs
cp /tmp/working/*.deb /tmp/working/Martus-5.0.2.zip /tmp/working/squashfs-root/tmp/

# chroot into the squashfs
echo -e "\n\nInstalling Martus into Tails root filesystem"
cp /tmp/working/chroot-tasks.sh /tmp/working/squashfs-root/tmp
sudo chroot /tmp/working/squashfs-root /tmp/chroot-tasks.sh


echo -e "\n\nCreating new Martus Tails ISO image..."
mkdir -p /tmp/mtails-iso
sudo rsync -av /tmp/tails-iso/mnt /tmp/mtails-iso

echo -e "\n\nInstalling Martus Documentation"
cd /tmp/working/squashfs-root/usr/share/doc
sudo tar -xzvf /tmp/working/martus-documentation.tgz
sudo cp /tmp/working/martus-documentation.desktop /tmp/working/squashfs-root/etc/skel/Desktop
sudo cp /tmp/working/martus-application.desktop /tmp/working/squashfs-root/etc/skel/Desktop
sudo cp /tmp/working/martus-documentation /tmp/working/squashfs-root/usr/local/bin/
sudo chmod 755 /tmp/working/squashfs-root/usr/local/bin/martus-documentation

echo -e "\n\nInstalling icons and desktop background"
sudo cp /tmp/working/martus-background.png /tmp/working/squashfs-root/usr/share/tails/desktop_wallpaper.png
sudo cp /tmp/working/martus-app.png /tmp/working/martus-docs.png /tmp/working/squashfs-root/usr/share/icons/gnome/48x48/categories/
sudo rm /tmp/working/squashfs-root/etc/skel/Desktop/Report_an_error.desktop

echo -e "\n\nCompressing the root directory"
sudo mksquashfs /tmp/working/squashfs-root /tmp/mtails-iso/filesystem.squashfs -b 1024k -comp xz -Xbcj x86 -e boot

echo -e "\n\nInserting the root directory into Mtails ISO"
sudo cp /tmp/mtails-iso/filesystem.squashfs /tmp/mtails-iso/mnt/live/

echo -e "\n\nwriting ISO file.."
sudo rm -f /tmp/mtails-iso/mtails-1.2.3-5.0.2.iso
sudo mkisofs -r -V "M-Tails" -cache-inodes -J -l -no-emul-boot -boot-load-size 4 -boot-info-table -o /tmp/mtails-iso/mtails-1.2.3-5.0.2.iso -b isolinux/isolinux.bin -c isolinux/boot.cat /tmp/mtails-iso/mnt

#sudo umount -f /tmp/tails-iso/mnt
#sudo umount -f /tmp/mtails-iso/mnt

echo -e  "\n\nInstallation complete.  You can find the iso image in /tmp/mtails-iso"
exit 0
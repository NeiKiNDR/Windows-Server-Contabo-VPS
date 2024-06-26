#!/bin/bash

apt update -y

apt install grub2 filezilla gparted wimtools -y

#Get the disk size in GB and convert to MB
disk_size_gb=$(parted /dev/sda --script print | awk '/^Disk \/dev\/sda:/ {print int($3)}')
disk_size_mb=$((disk_size_gb * 1024))

#Calculate partition size (25% of total size)
part_size_mb=$((disk_size_mb / 4))

#Create GPT partition table
parted /dev/sda --script -- mklabel gpt

#Create two partitions
parted /dev/sda --script -- mkpart primary ntfs 1MB ${part_size_mb}MB
parted /dev/sda --script -- mkpart primary ntfs ${part_size_mb}MB $((2 * part_size_mb))MB

#Inform kernel of partition table changes
partprobe /dev/sda

sleep 30

partprobe /dev/sda

sleep 30

partprobe /dev/sda

sleep 30 

#Format the partitions
mkfs.ntfs -f /dev/sda1
mkfs.ntfs -f /dev/sda2

echo "NTFS partitions created"

echo -e "r\ng\np\nw\nY\n" | gdisk /dev/sda

mount /dev/sda1 /mnt

#Prepare directory for the Windows disk
cd ~
mkdir windisk

mount /dev/sda2 windisk

grub-install --root-directory=/mnt /dev/sda

#Edit GRUB configuration
cd /mnt/boot/grub
cat <<EOF > grub.cfg
menuentry "windows installer" {
	insmod ntfs
	search --set=root --file=/bootmgr
	ntldr /bootmgr
	boot
}
EOF

cd /root/windisk

mkdir winfile

wget -O win10.iso https://dn790002.ca.archive.org/0/items/windows-10-enterprise-ltsc-2021-x-64-dvd-esp/Windows_10_enterprise_ltsc_2021_x64_dvd_es-es_51d721ea.iso

mount -o loop win10.iso winfile

rsync -avz --progress winfile/* /mnt

umount winfile

wget -O virtio.iso https://shorturl.at/lsOU3

mount -o loop virtio.iso winfile

mkdir /mnt/sources/virtio

rsync -avz --progress winfile/* /mnt/sources/virtio

cd /mnt/sources

touch cmd.txt

echo 'add virtio /virtio_drivers' >> cmd.txt

wimlib-imagex update boot.wim 2 < cmd.txt

reboot



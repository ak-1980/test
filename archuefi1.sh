#!/bin/bash

loadkeys ru
setfont cyr-sun16
echo 'Скрипт сделан на основе чеклиста Бойко Алексея по Установке ArchLinux'
echo 'Ссылка на чек лист есть в группе vk.com/arch4u'

echo '2.3 Синхронизация системных часов'
timedatectl set-ntp true
echo '2.4 создание разделов'
(
 echo g;

 echo n;
 echo ;
 echo;
 echo +300M;
 echo y;
 echo t;
 echo 1;

 echo n;
 echo;
 echo;
 echo +30G;
 echo y;
 
  
 echo n;
 echo;
 echo;
 echo;
 echo y;
  
 echo w;
) | fdisk /dev/$sd_disk

echo 'Ваша разметка диска'
fdisk -l
read -p "Select a disk sd.. " sd_disk
echo "selected a disk $sd_disk.."
echo '2.4.2 Форматирование дисков'
sd_1+=$sd_disk"1"
sd_2+=$sd_disk"2"
sd_3+=$sd_disk"3"
mkfs.fat -F32 /dev/$sd_1
mkfs.ext4  /dev/$sd_2
mkfs.ext4  /dev/$sd_3

echo '2.4.3 Монтирование дисков'
mount /dev/$sd_2 /mnt
mkdir /mnt/home
mkdir -p /mnt/boot/efi
mount /dev/$sd_1 /mnt/boot/efi
mount /dev/$sd_3 /mnt/home

echo '3.1 Выбор зеркал для загрузки.'
rm -rf /etc/pacman.d/mirrorlist
wget https://git.io/mirrorlist
mv -f ~/mirrorlist /etc/pacman.d/mirrorlist

echo '3.2 Установка основных пакетов'
pacstrap /mnt base base-devel linux linux-firmware nano dhcpcd netctl

echo '3.3 Настройка системы'
genfstab -pU /mnt >> /mnt/etc/fstab

arch-chroot /mnt sh -c "$(curl -fsSL github.com/AlexeyKozma/test/raw/master/archuefi2.sh)"

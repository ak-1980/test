#!/bin/bash
read -p "Введите имя компьютера: " hostname
read -p "Введите имя пользователя: " username

echo 'Прописываем имя компьютера'
echo $hostname > /etc/hostname
ln -svf /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime

echo '3.4 Добавляем русскую локаль системы'
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 
echo "ru_RU.KOI8-R KOI8-R" >> /etc/locale.gen
echo "ru_RU.CP1251 CP1251" >> /etc/locale.gen
echo "ru_RU ISO-8859-5" >> /etc/locale.gen

echo 'Обновим текущую локаль системы'
locale-gen

echo 'Указываем язык системы'
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf

echo 'Вписываем KEYMAP=ru FONT=cyr-sun16'
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf

echo 'Создадим загрузочный RAM диск'
mkinitcpio -p linux

echo '3.5 Устанавливаем загрузчик'
pacman -Syy
pacman -S grub #os-prober #grub efibootmgr --noconfirm 
#grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch --force
grub-install /dev/$sd_disk || grub-install --recheck /dev/$sd_disk
echo 'Обновляем grub.cfg'
#grub-install --target=i386-pc /dev/$sd_disk
#grub-mkconfig -o /boot/grub/grub.cfg
echo 'Ставим программу для Wi-fi'
pacman -S dialog wpa_supplicant --noconfirm 

echo 'Добавляем пользователя'
useradd -m -g users -G wheel -s /bin/bash $username

echo 'Создаем root пароль'
passwd

echo 'Устанавливаем пароль пользователя'
passwd $username

echo 'Устанавливаем SUDO'
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

echo 'Раскомментируем репозиторий multilib Для работы 32-битных приложений в 64-битной системе.'
echo '[multilib]' >> /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
pacman -Syy

echo "Куда устанавливем Arch Linux на виртуальную машину?"
read -p "1 - Да, 0 - Нет: " vm_setting
if [[ $vm_setting == 0 ]]; then
  pacman -S xorg-server xorg-drivers xorg-utils xorg-apps xorg-xinit
elif [[ $vm_setting == 1 ]]; then
  pacman -S xorg-server xorg-drivers xorg-xinit virtualbox-guest-utils
fi

Xorg :0 -configure
cp /root/xorg.conf.new /etc/X11/xorg.conf

echo "Какое DE ставим?"
read -p "XFCE - 1, KDE - 2, i3-wm - 3 , Deepen - 4, GNOME - 5, or No de - 0" vm_setting
if [[ $vm_setting == 1 ]]; then
  pacman -S xfce4 xfce4-goodies xfce4-session xfce4-whiskermenu-plugin sddm --noconfirm
elif [[ $vm_setting == 2 ]]; then
  pacman -Sy plasma plasma-wayland-session kde-applications-meta --noconfirm
  # pacman -Sy kde-applications-meta --noconfirm
  # pacman -Sy plasma-wayland-session --noconfirm
elif [[ $vm_setting == 3 ]]; then 
  pacman -S i3-wm i3status dmenu 
  pacman -S pcmanfm #thunar
  pacman -S sbxkb ttf-font-awesome feh lxappearance gvfs udiskie xorg-xbacklight ristretto tumbler compton
  pacman -S alacritty kitty 
  pacman -S qt5ct qt5-style rxvt-unicode-patched urxvt-perls ttf-nerd-fonts-hack-complete-git
  echo 'exec i3' >> /home/$username/.xinitrc
  mkdir  /home/$username/.i3/
  echo 'exec i3 -V' >> /home/$username/.i3/i3log 2>&1
elif [[ $vm_setting == 4 ]]; then  
  pacman -S  deepin deepin-extra 
elif [[ $vm_setting == 5 ]]; then
  pacman -S gnome gnome-extra
fi


echo 'Ставим DM'

if [[ $vm_setting == 1 ]] || [[ $vm_setting == 0 ]]; then
  #pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
  #systemctl start lightdm
  #systemctl enable lightdm
  systemctl start sddm
  systemctl enable sddm
fi

if [[ $vm_setting == 2 ]]; then
  systemctl start sddm
  systemctl enable sddm
fi

if [[ $vm_setting == 3 ]]; then	
  pacman -S sddm
  systemctl start sddm
  systemctl enable sddm
fi

if [[ $vm_setting == 4 ]]; then
  # pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
  # systemctl start lightdm
  systemctl enable lightdm
fi

if [[ $vm_setting == 5 ]]; then
 systemctl start gdm
 systemctl enable gdm
 pacman -S networkmanager gnome-keyring
fi
read -p "Installing dirctory of user  = 1 or 0 : " in_d_u
if [[ $in_d_u == 1 ]]; then
	pacman -S xdg-user-dirs --noconfirm
	xdg-user-dirs-update
fi
read -p "installing programs = 1 or 0: " in_p
if [[ $in_p == 1 ]]; then
	echo 'Установка программ'
   pacman -S gcc gdb make cmake git wget curl recoll obs-studio doublecmd-gtk2 veracrypt vlc freemind filezilla gimp libreoffice libreoffice-fresh-ru kdenlive audacity screenfetch qbittorrent galculator chromium ufw f2fs-tools dosfstools ntfs-3g alsa-lib alsa-utils file-roller p7zip unrar gvfs aspell-ru pulseaudio pavucontrol --noconfirm
fi
read -p "Install alsa 1 or 0: " alsa
if [[ $alsa == 1 ]]; then 
	pacman -S alsa-utils alsa-plugins
fi

echo 'Установка AUR (yay)'
pacman -S --needed git base-devel --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si && cd .. && yay -S cherrytree pamac-aur-git  --noconfirm 

echo 'Ставим шрифты'
pacman -S ttf-liberation ttf-dejavu --noconfirm 

echo 'Ставим сеть'
pacman -S networkmanager network-manager-applet ppp --noconfirm

echo 'Подключаем автозагрузку менеджера входа и интернет'
systemctl start NetworkManager
systemctl enable NetworkManager
echo 'Установка завершена! Перезагрузите систему.'
echo 'Если хотите подключить AUR, установить мои конфиги XFCE4,KDE 5 тогда после перезагрзки и входа в систему, установите wget (sudo pacman -S wget) и выполните команду:'
echo 'wget github.com/AlexeyKozma/test/raw/master/archuefi3.sh && sh archuefi3.sh'
exit

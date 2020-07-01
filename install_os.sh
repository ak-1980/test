#!/bin/bash

function diskor()
{
    while [[ true ]]; do
    lsblk
    read -p "Введите имя диска, куда булет установлен Archlinux.
    Пример sda, sdb ...
    Или введит 'q' для выхода: " disk_name
    if [[ $disk_name == 'q' ]]; then
        return 0
    read -p "Выбран диск $disk_name подтвердить" disk_on
    elif [[ $disk_on == 'y' ]] || [[ $disk_on == 'yes' ]]; then 


        echo 'создание разделов'
        (
        echo g;

        echo n;
        echo;
        echo;
        echo +512M;
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
        ) | fdisk /dev/$disk_name 

        echo 'Форматирование дисков'
        sd_1=$disk_name'1'
        sd_2=$disk_name'2'
        sd_3=$disk_name'3'
        mkfs.fat -F32 /dev/$sd_1 &&
        mkfs.ext4  /dev/$sd_2 &&
        mkfs.ext4  /dev/$sd_3 &&

        echo 'Монтирование дисков' &&
        mount /dev/$sd_2 /mnt &&
        mkdir /mnt/home &&
        mkdir -p /mnt/boot/efi &&
        mount /dev/$sd_1 /mnt/boot/efi &&
        mount /dev/$sd_3 /mnt/home && 
        return 0
    
    fi
    done

   return 1
}

function mirrors()
{
    echo 'Выбор зеркал для загрузки.'
    rm -rf /etc/pacman.d/mirrorlist &&
    wget https://github.com/AlexeyKozma/test/raw/master/mirrorlist && 
    mv -f ~/mirrorlist /etc/pacman.d/mirrorlist &&
    return 0
}

function install_base()
{   
    count=1
    while [ $count -lt 5 ]; do
        pacstrap /mnt base base-devel btrfs-progs dmidecode dosfstools e2fsprogs efibootmgr exfat-utils 
        f2fs-tools fakeroot findutils gptfdisk grep grub haveged hdparm intel-ucode ipw2100-fw 
        ipw2200-fw less linux linux-atm linux-firmware linux-headers lsb-release lvm2 memtest86+ 
        ntfs-3g os-prober refind-efi reiserfsprogs rsync shadow smartmontools syslinux  
        systemd-sysvcompat tar tlp upower usb_modeswitch usbutils util-linux wget wireless_tools 
        wireless-regdb wvdial x264 xfsprogs
        if [[ $? ]]; then
            genfstab -pU /mnt >> /mnt/etc/fstab
            return 0
        fi
        let $count+=1 
    done
}

function configuration_os()
{
    clear
    while [[ true ]]; do
        arch-chroot /mnt
        printf "###############\n
        # 1) Установка имени компьтера\n# 2) Установка имя пользователя\n# 3) Настройка часового пояса\n# 4) Локализация\n#
        5) Установка языка системы\n# 6) Установка шрифта для консоли\n# 7) Загрузочный RAM диск\n# 8) Установщик загрузчика\n# 
        9) Установка программ для Wi-Fi\n# 10) Добавления пользователя\n# 11) Создание root пароля\n# 
        # 12) Устанавка пароля пользователя\n# 13) Репозиторий multilib для работы 32-битных приложений\n# 14) Установка видеодрайверов\n"  
        read -p ": " type_
        case $type_ in 
        1) read -p "Введите имя компьютера: " hostname  
        echo $hostname > /etc/hostname ;;
        2) read -p "Введите имя пользователя: " username ;;
        3) echo "Установка часовго пояса по умолчанию.." 
        ln -svf /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime ;;
        4) echo 'Добавляем русскую локаль системы'
            echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
            echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 
            echo "ru_RU.KOI8-R KOI8-R" >> /etc/locale.gen
            echo "ru_RU.CP1251 CP1251" >> /etc/locale.gen
            echo "ru_RU ISO-8859-5" >> /etc/locale.gen 
            echo 'Обновим текущую локаль системы'
            locale-gen ;;
        5)  echo 'Указываем язык системы'
            echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf ;;  
        6)  echo 'Вписываем KEYMAP=ru FONT=cyr-sun16'
            echo 'KEYMAP=ru' >> /etc/vconsole.conf
            echo 'FONT=cyr-sun16' >> /etc/vconsole.conf ;;   
        7)  echo 'Создадим загрузочный RAM диск'
            mkinitcpio -p linux ;;  
        8)  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch --force ;;     
        9)  echo 'Ставим программу для Wi-fi'
            pacman -S dialog wpa_supplicant --noconfirm ;;   
        10) echo 'Добавляем пользователя'
            useradd -m -g users -G wheel -s /bin/bash $username ;;  
        11) echo 'Создаем root пароль'
            passwd ;;  
        12) echo 'Устанавливаем пароль пользователя'
            passwd $username
            echo 'Устанавливаем SUDO'
            echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers ;;
        13) echo 'Раскомментируем репозиторий multilib Для работы 32-битных приложений в 64-битной системе.'
            echo '[multilib]' >> /etc/pacman.conf
            echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
            pacman -Syy ;;
        14) echo "Куда устанавливем Arch Linux на виртуальную машину?"
            read -p "1 - Да, 0 - Нет: " vm_setting
            if [[ $vm_setting == 0 ]]; then
            pacman -S xorg-server xorg-drivers xorg-utils xorg-apps xorg-xinit
            elif [[ $vm_setting == 1 ]]; then
            pacman -S xorg-server xorg-drivers xorg-xinit virtualbox-guest-utils
            fi
            Xorg :0 -configure
            cp /root/xorg.conf.new /etc/X11/xorg.conf  ;;              
        esac
        exit  
    done
}

# menu 1) Информация облочных устройствых (Дисках)


function menu_install()
{
    local result
    # Этапы установки 
    # Вывод инвормации 
    while [[ true ]]
    do
    clear
    printf "############# \n# 1) разметка жесткого диска\n# 2) Выбор зекал\n# 3) Установка основных пакетов \n
    # 4) Базовые настройки # 5) Выход \n############# Ввод:"
    read -p "  " exit_e
        case $exit_e in 
        1) diskor ;;
        2) mirrors ;;
        3) install_base ;;
        4) configuration_os ;;
        5) break ;;
        esac
    done
} 


menu_install
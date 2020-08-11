#!/bin/bash

# default 
locale=ru_RU
font=cyr-sun16
keymap=ru
region=Asia
city=Yekaterinburg
loadkeys=ru
setfont cyr-sun16
hostname=pc1
username=user
hard_drive=Nun
table_type=1
efi_or_bios=1
disk_partition_boot=512
disk_partition_root=30
disk_partition_swap=0
disk_partition_home=0

boot_dialog() {
    DIALOG_RESULT=$(whiptail --clear --backtitle " Arch Linux" "$@" 3>&1 1>&2 2>&3)
    DIALOG_CODE=$?
}

DIALOG=${DIALOG=dialog}


function build_structure_fs() {
    t_t=g
    if [[ $table_type -eq 2 ]] ; then 
      t_t=o
    fi 

    #fdisk /dev/$hard_drive << EOF
    fdisk /dev/$hard_drive << EOF
    echo -e "$t_t\nn\np\n\n\n+512M\na\nw"
EOF
    
    
}

function fs_build_structure() {
    boot_dialog --title "Все параметры, которые вы указали вступят в силу!" \
    --yesno "Yes/No" 10 40

   return $?
}

function hard_drive_mark() {
    boot_dialog --title "Меню работы с дисками" \
    --menu "" 15 60 6 "1" "Информация" "2" "Выбрать диск для установки (default - $hard_drive)" \
    "3" "Выбор таблицы разделов (default - $table_type)" "4" "Разметка диска" "5" "Форматирование разделов" "6" "Выход"
    return "$DIALOG_RESULT"
}

function hard_drive_split() {
    boot_dialog --title "Размета диска" \
    --menu "" 15 60 4 "1" "Раздел Boot (default - $efi_or_bios - $disk_partition_boot M)" \
    "2" "Раздел Root (default - $disk_partition_root G)" \
    "3" "Раздел Swap (default - $disk_partition_swap G)" \
    "4" "Раздел Home (default - $disk_partition_home G or free space)" \
    "5" "Применить изменения" \
    "6" "Выход"

    return "$DIALOG_RESULT"

}

function disk_partition_input_boot() {
    boot_dialog --title "Установка размера раздела boot" --inputbox "Введите размер в M или \n0 для отключения раздела" 10 60
    disk_partition_boot="$DIALOG_RESULT"
}

function disk_partition_input_root() {
    boot_dialog --title "Установка размера раздела root" --inputbox "Введите размер в G или \n0 для отключения раздела" 10 60
    disk_partition_root="$DIALOG_RESULT"
}

function disk_partition_input_home() {
    boot_dialog --title "Установка размера раздела home" --inputbox "Введите размер в G или \n0 для отключения раздела" 10 60
    disk_partition_home="$DIALOG_RESULT"
}

function disk_partition_input_swap() {
    boot_dialog --title "Установка размера раздела swap" --inputbox "Введите размер в G или \n0 для отключения раздела" 10 60
    disk_partition_swap="$DIALOG_RESULT"
}

function hard_drive_type_table() {
    boot_dialog --radiolist "Выбор типа таблицы" 10 60 2 \
    1 "Partition Table (GPT) - Современный формат" on \
    2 "Master Boot Record (MBR) - Устаревший формат" off
    table_type="$DIALOG_RESULT"
}

function hard_drive_select() {
    boot_dialog --title "Выбор диска" --inputbox "Введите размер в " 10 60
    hard_drive="$DIALOG_RESULT"
}

function hard_drive_info() {
    dialog --infobox "$( lsblk )" 10 60 ; sleep 10
    return  "$DIALOG_RESULT"
}


function select_password_user() {
    boot_dialog --title "User password" --passwordbox "Please enter a strong password for the user.\n" 10 60
    user_password="$DIALOG_RESULT"
}

function select_password_root() {
    boot_dialog --title "Root password" --passwordbox "Please enter a strong password for the root user.\n" 10 60
    root_password="$DIALOG_RESULT"
}

function select_username() {
    boot_dialog --title "User name" --inputbox "Please enter a name for this user.\n" 10 60
    username="$DIALOG_RESULT"
}

function select_hostname() {
    boot_dialog --title "Hostname" --inputbox "\nPlease enter a name for this host.\n" 10 60
    hostname="$DIALOG_RESULT"
}

function select_file_system() {
    boot_dialog --title "File systems" --menu "" 10 60 2 "1" "EXT4" "2" "BTRFS" 
    s_f_s="$DIALOG_RESULT"
}

function select_desktop_environment() {
    boot_dialog --title "Desktop environment" --menu "" 10 60 4 "1" "XFCE" "2" "MATE" "3" "KDE" "4" "WITHOUT DE"
    s_d_e="$DIALOG_RESULT"
}

function select_display_drivers() {
    boot_dialog --title "Display drivers" --menu "" 16 60 6 "1" "VIRTUALBOX" "2" "VMware" "3" "INTEL" "4" "ATI" "5" "AMD" "6" "NVIDIA"
    s_d_d="$DIALOG_RESULT"
}

function select_font() {
    items=$(find /usr/share/kbd/consolefonts/*.psfu.gz -printf "%f\n" | cut -f1 -d.)
    options=()
    for item in $items; do
        options+=("$item" "")
    done
    boot_dialog --title "Font" --menu "" 16 60 7 "${options[@]}" 
    font="$DIALOG_RESULT"
}

function select_keymap() {
    items=$(find /usr/share/kbd/keymaps/ -type f -printf "%f\n" | sort -V | awk -F'.map' '{print $1}')
    options=()
    for item in $items; do
        options+=("$item" "")
    done
    boot_dialog --title "Keymap" --menu "" 16 60 7 "${options[@]}"  
    keymap="$DIALOG_RESULT" 
}

function select_locale() {
    items=$(ls /usr/share/i18n/locales)
    options=()
    for item in $items; do
        options+=("$item" "")
    done
    boot_dialog --title "Locale" --menu "" 16 60 7 "${options[@]}" 
    locale="$DIALOG_RESULT"
}

function select_locale_time() {
    items=$(ls -l /usr/share/zoneinfo/ | grep '^d' | gawk -F':[0-9]* ' '/:/{print $2}') 
    options=()
    for item in $items; do
        options+=("$item" "")
    done
    boot_dialog --title "Timezone" --menu "" 16 60 7 "${options[@]}"  
    region="$DIALOG_RESULT"

    items=$(ls /usr/share/zoneinfo/$region/) 
    options=()
    for item in $items; do
        options+=("$item" "")
    done
    boot_dialog --title "Timezone" --menu "" 16 60 7 "${options[@]}" 
    city="$DIALOG_RESULT"
}

function menu_install_1() {
    boot_dialog --title "Меню установки системы" \
    --menu "Пожалуйста выберите пункт меню и нажмите на <ENTER>:" 15 55 5 \
    1 "Язык системы (default - $locale)" \
    2 "Шрифт консоли (default - $font)" \
    3 "Раскладка клавиатуры (default - $keymap)" \
    4 "Локальное время (default - $region - $city)" \
    5 "Имя компьютера (default - $hostname)" \
    6 "Установка пароля для root" \
    7 "Установка имени пользователя (default - $username)" \
    8 "Установка пароля для пользователя" \
    9  "Разметка диска" \
    10 "Установка базовой системы " \
    11 "Установка видео-драйверов" \
    12 "Установка графической оболочки" \
    13 "Настройка системы" \
    14 "Выход" 

    return "$DIALOG_RESULT"
}


function main() {
    while true ; do
        menu_install_1
        case $? in 
            1) select_locale ;;
            2) select_font ;;
            3) select_keymap ;;
            4) select_locale_time ;;
            5) select_hostname ;;
            6) select_password_root ;;
            7) select_username ;;
            8) select_password_user ;;
            9) while true ; do 
                hard_drive_mark 
                case $? in 
                1)  hard_drive_info ;;
                2)  hard_drive_select ;;
                3)  hard_drive_type_table ;;
                4)  while true ; do
                    hard_drive_split 
                    case $? in
                        1) disk_partition_input_boot ;;
                        2) disk_partition_input_root ;;
                        3) disk_partition_input_swap ;;
                        4) disk_partition_input_home ;;
                        5) fs_build_structure
                           if [[ $? -eq 0 ]] ; then
                            build_structure_fs
                           else continue  
                           fi
                           ;;
                        6) break ;; 
                    esac
                done
                ;;
                5)  ;;
                6) break ;;
                esac
            done
            ;;
            10) ;;
            11) select_display_drivers ;;
            12) select_desktop_environment ;;
            13) ;;
            14) return 14
        esac
    done
}

main
clear
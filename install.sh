#!/bin/zsh

location="/usr/share/zoneinfo/America/Caracas"
host=jackestar
boot_dev=""

echo -e "\e[1m\e[4mJackestar Custom Arch Instalation\e[0m\e[0m\n"
installation_packages=""

hardware_packages() {
    if [ ! -f /proc/cpuinfo ]; then
    echo "Cannot find /proc/cpuinfo..."
    exit 1
    fi
    
    VENDOR_ID=$(grep -m 1 "vendor_id" /proc/cpuinfo | awk '{print $3}' | uniq)
    
    # Use a case statement to check the vendor ID and report the result.
    case "$VENDOR_ID" in
        "GenuineIntel")
            echo -e "You have an \e[36mIntel\e[0m processor."
            installation_packages+="intel-ucode "
            ;;
        "AuthenticAMD")
            echo -e "You have an \e[31mAMD\e[0m processor."
            installation_packages+="amd-ucode "
            ;;
        *)
            # If it's not Intel or AMD, print what was found.
            if [ -n "$VENDOR_ID" ]; then
                echo "Your processor is from an unrecognized vendor: $VENDOR_ID"
                # exit 1
            else
                echo "Could not determine the processor vendor."
                # exit 1
            fi
            ;;
    esac
}

cfdisk_operation() {
  echo "  Executing: blkid"
  blocks="$(lsblk)"
  echo "$blocks"

    directions=($(lsblk -d -o NAME -n | sed 's|^|/dev/|'))
    echo ""
    select dev in "${directions[@]}"; do
      if [[ -n $dev ]]; then
          echo "Selected: $dev"
          cfdisk $dev
          break
      else
          echo "direction invalid"
      fi
    done
    read -p "Do you want to continue formating disks? (yes/no): " answer
    while true; do
      case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            break
            ;;
        [Nn]|[Nn][Oo])
            return 1
            break
            ;;
        *)
            echo "Invalid answer"
            ;;
      esac
    done
    return 1
}

partition_format() {
        # / /boot /home
    # /
    blkid
    mapfile -t devices < <(blkid | cut -d' ' -f1 | sed 's/://')
    echo -e "\n\e[1m\e[4mSelect you '/' drive\e[0m\e[0m\n"
    
    select dev in "${devices[@]}"; do
      if [[ -n $dev ]]; then
        if [[ $1 == "true" ]]; then
            mkfs.ext4 $dev
        fi
  
          mount $dev /mnt
        break
      fi
    done

    # /boot
    blkid
    mapfile -t devices < <(blkid | cut -d' ' -f1 | sed 's/://')
    echo -e "\n\e[1m\e[4mSelect you '/boot' (EFI) drive\e[0m\e[0m\n"
    
    select dev in "${devices[@]}"; do
      if [[ -n $dev ]]; then
        if [[ $1 == "true" ]]; then
            mkfs.fat -F 32 $dev  
        fi
          mount --mkdir $dev /mnt/boot
          boot_dev=$dev
        break
      fi
    done

    # /swap
    blkid
    mapfile -t devices < <(blkid | cut -d' ' -f1 | sed 's/://')
    echo -e "\n\e[1m\e[4mSelect you swap drive\e[0m\e[0m\n"
    
    select dev in "${devices[@]}"; do
      if [[ -n $dev ]]; then
        if [[ $1 == "true" ]]; then
            mkswap $dev
        fi
          swapon $dev
        break
      fi
    done
}

# Enviroment
if grep -q "archiso" /etc/hostname; then # testpoint
  echo -e "\e[36mInstalation enviroment\e[0m"
    echo ""

    # cfdisk
    while true; do
      read -p "Do you want to format disks (cfdisk)? (yes/no): " answer
      case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            if ! cfdisk_operation; then
              break
            fi
            ;;
        [Nn]|[Nn][Oo])
            break
            ;;
        *)
            echo "Invalid answer"
            ;;
      esac
    done

    while true; do
      read -p "Do you want to format partitions (yes/no): " answer
      case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            partition_format true
            break
            ;;
        [Nn]|[Nn][Oo])
            partition_format
            break
            ;;
        *)
            echo "Invalid answer"
            ;;
      esac
    done

    # MULTILIB
    # Ram dependent (-Sy <4 Suy >=8)
    pacman -Sy patch
    patch /etc/pacman.conf < patches/pacman.patch

    # Pactrap
    # Essentials Packages
    installation_packages+="base base-devel bluez bluez-utils brightnessctl cpupower cups cups-pdf efibootmgr ffmpeg grub grim iwd linux linux-zen linux-firmware-intel linux-firmware-realtek os-prober pipewire samba sane smbclient unrar wf-recorder unzip wget wine wine-gecko wine-mono winetricks wlr-randr zsh zsh-completions xdg-user-dirs openvpn ntfs-3g ntp x86_energy_perf_policy networkmanager networkmanager-openvpn man-db "
    installation_packages+="pipewire pipewire-alsa pipewire-pulse "
    # Terminal/Console
    installation_packages+="htop kitty vim neovim "
    # UI
    installation_packages+="hyprland hyprpaper rofi sddm waybar wayland ttf-roboto-mono-nerd ttf-hack-nerd "
    installation_packages+="gtk4 gtk3 papirus-icon-theme  "
    # QOL
    installation_packages+="android-file-transfer android-tools "
    # Browsers
    installation_packages+="firefox-developer-edition firefox-developer-edition-i18n-es-mx "
    # Utility
    installation_packages+="qbittorrent gimp inkscape kicad kicad-library kicad-library-3d lxappearance nemo nemo-fileroller nemo-share pavucontrol vlc-plugins-all vlc yt-dlp gnome-disk-utility "
    # DEV
    installation_packages+="git github-cli pnpm npm rustup "

    # AVR-DEV
    read -p "Do you want to install AVR dev packages? (yes/no): " answer
    while true; do
      case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            installation_packages+="avrdude avr-gcc avr-libc "
            break
            ;;
        [Nn]|[Nn][Oo])
            break
            ;;
        *)
            echo "Invalid answer"
            ;;
      esac
    done

    # AVR-DEV
    read -p "Do you want to install Audio/Music editors packages? (yes/no): " answer
    while true; do
      case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            installation_packages+="audacity musescore "
            break
            ;;
        [Nn]|[Nn][Oo])
            break
            ;;
        *)
            echo "Invalid answer"
            ;;
      esac
    done

    pacstrap -K /mnt ${installation_packages}
    genfstab -U /mnt >> /mnt/etc/fstab
    cp in_chroot.sh /mnt/root/in_chroot.sh
    cp patches/*.patch /mnt/root/

    # SDDM
    mkdir /mnt/etc/sddm.conf.d/
    cp 10-wayland.conf /mnt/etc/sddm.conf.d/10-wayland.conf
    cp sddm.conf /mnt/etc/sddm.conf

    cp img/logo-cpc.png /mnt/root/logo-cpc.png
    cp NetworkManager.conf /mnt/etc/NetworkManager/NetworkManager.conf

    # git clone https://github.com/catppuccin/papirus-folders.git
    # cd papirus-folders
    # sudo cp -r papirus-folders/src/* /mnt/usr/share/icons/Papirus

    arch-chroot /mnt sh /root/in_chroot.sh $boot_dev

    # After
    cp img/logo-cpc.png /mnt/usr/share/grub/themes/catppuccin-mocha-grub-theme/logo.png

    arch-chroot
    cp -r hypr/ /mnt/home/$host/.config/
    cp ./img/background.png /mnt/home/$host/.apps/background.png

    # patch SDDM
    patch /mnt/usr/share/sddm/themes/sddm-astronaut-theme/Main.qml < patches/Main.qml.patch
    patch /mnt/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop < patches/metadata.desktop.patch
    cp ./pixel_sakura-time.conf /mnt/usr/share/sddm/themes/sddm-astronaut-theme/Themes/pixel_sakura-time.conf
    cp ./img/pixel_sakura-*.gif /mnt/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/

    # waybar
    cp -r waybar/ /mnt/home/$host/.config/

    # kitty
    mkdir /mnt/home/$host/.config/kitty/
    cp kitty.conf /mnt/home/$host/.config/kitty/kitty.conf

    # zsh

    cp /mnt/usr/share/oh-my-zsh/zshrc /mnt/root/.zshrc
    cp /mnt/usr/share/oh-my-zsh/zshrc /mnt/home/$host/.zshrc
    cp .p10k.zsh /mnt/home/$host/

    cp zshrc /mnt/etc/zsh/zshrc
    patch /mnt/home/$host/.zshrc < patches/zshrc.patch

    # Failed in user but not in root without \n
    echo -e '\nsource /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >> /mnt/root/.zshrc
    echo -e '\nsource /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >> /mnt/home/$host/.zshrc

    # AVR
    cp 01-ttyusb.rules /mnt/etc/udev/rules.d/
    
    # giving ownership
    arch-chroot /mnt chown $host:$host -R /home/$host/

else
    echo -e "\e[33mOS enviroment\e[0m"
fi
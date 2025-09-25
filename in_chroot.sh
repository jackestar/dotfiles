#!/bin/zsh

location="/usr/share/zoneinfo/America/Caracas"
host=jackestar
boot_dev=$1

ln -sf $location /etc/localtime
hwclock --systohc
locale-gen
timedatectl set-ntp true
echo $host > /etc/hostname


echo -e "\n\e[1m\e[4mSet you root passwd\e[0m\e[0m\n"
passwd

parent=$(lsblk -no PKNAME $boot_dev)
mkdir /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=Arch-JS --efi-directory /boot/ /dev/$parent

echo -e "\n\e[1m\e[4mSetting up User $host\e[0m\e[0m\n"

groupadd dialout
groupadd plugdev
useradd -m -G scanner,wheel,dialout,plugdev,input -s /bin/zsh $host
echo -e "\n\e[1m\e[4mSet you $host passwd\e[0m\e[0m\n"
passwd $host

# sudoers
patch /etc/sudoers < /root/sudoers.patch

xdg-user-dirs-update

echo -e "\n\e[1m\e[4mInstalling AUR Helper paru\e[0m\e[0m\n"
cd /home/$host/
git clone https://aur.archlinux.org/paru.git
chmod -R 777 ./paru
# cd paru
sudo -u jackestar  rustup default stable
sudo -u jackestar makepkg -si -D ./paru

rm -rf ./paru

cd /root/

# Setup SAMBA
# Base Samba config
wget 'https://git.samba.org/samba.git/?p=samba.git;a=blob_plain;f=examples/smb.conf.default;hb=HEAD' -O /etc/samba/smb.conf
systemctl enable smb
echo -e "\n\e[1m\e[4mSet you samba $host passwd\e[0m\e[0m\n"
smbpasswd -a $host
# Parche
patch /etc/samba/smb.conf < smb.conf.patch

# enable services

systemctl enable iwd
systemctl enable bluetooth

# x86_energy_perf_policy --turbo-enable 1
cpupower frequency-set -g performance
systemctl enable cpupower
systemctl enable NetworkManager
systemctl enable sddm

# GRUB Theme
git clone https://github.com/catppuccin/grub.git
cp -r grub/src/* /usr/share/grub/themes/
rm -rf  grub

patch /etc/default/grub < grub.patch

grub-mkconfig -o /boot/grub/grub.cfg

sudo -u jackestar paru -Suy sddm-astronaut-theme nomacs fastfetch fritzing google-chrome sublime-text-4 visual-studio-code-bin arduino-ide catppuccin-gtk-theme-mocha papirus-folders-catppuccin-git oh-my-zsh-git zsh-theme-powerlevel10k-git

patch /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop < metadata.desktop.patch

sudo -u jackestar paru -Scc
rm *.patch 

gsettings set org.gnome.desktop.interface gtk-theme catppuccin-mocha-blue-standard+default
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark

# curl -LO https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders && chmod +x ./papirus-folders
papirus-folders -C cat-mocha-blue --theme Papirus-Dark
# rm papirus-folders

mkdir /etc/iwd/
echo -e "[General]\nEnableNetworkConfiguration=true" > /etc/iwd/main.conf

# Rofi
mkdir /home/$host/.config/rofi
sudo -u jackestar rofi -dump-config > /home/$host/.config/rofi/config.rasi
echo '@import "./catppuccin-mocha"' >> /home/$host/.config/rofi/config.rasi
echo '@theme "catppuccin-default"' >> /home/$host/.config/rofi/config.rasi

git clone https://github.com/catppuccin/rofi
cp -r rofi/catppuccin-default.rasi /home/$host/.config/rofi/
cp -r rofi/themes/* /home/$host/.config/rofi/
sed -i '1i@import "catppuccin-mocha"' /home/$host/.config/rofi/catppuccin-default.rasi
sed -i '2ifont: "montserrat 12";' /home/$host/.config/rofi/config.rasi

# Some dirs

mkdir /home/$host/.config/hypr/
mkdir /home/$host/.apps
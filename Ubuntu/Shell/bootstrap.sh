#!/bin/bash
cd ~

sudo apt update
sudo apt -y upgrade

sudo apt -y install git curl wget vim zsh autojump fasd tmux gnome-tweak-tool gdebi fcitx-table-wbpy preload ntpdate flameshot gnome-shell-extensions gir1.2-lunar-date-2.0 filezilla gimp steam telegram-desktop virtualbox vlc grub-customizer ubuntu-restricted-extras

sudo ntpdate ntp.aliyun.com
sudo hwclock --localtime --systohc

git clone https://github.com/Guake/guake.git ~/Documents/guake
cd ~/Documents/guake
./scripts/bootstrap-dev-debian.sh run make
make
sudo make install
cd ~

curl http://j.mp/spf13-vim3 -L -o - | sh

wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

sudo snap install authy --beta

git clone https://github.com/eallion/dotfiles.git ~/Documents/dotfiles

echo "=============================="
echo "Done!"
echo "=============================="
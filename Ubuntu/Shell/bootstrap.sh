#!/bin/bash
cd ~

sudo apt update
sudo apt -y upgrade

sudo apt -y install git curl wget vim zsh autojump fasd tmux gnome-tweak-tool gdebi fcitx-table-wbpy preload ntpdate flameshot gnome-shell-extensions gir1.2-lunar-date-2.0 filezilla steam telegram-desktop virtualbox vlc grub-customizer ubuntu-restricted-extras

echo "=============================="
echo "Done!"
echo "=============================="
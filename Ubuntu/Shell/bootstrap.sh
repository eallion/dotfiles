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

# Docker 
sudo apt remove docker docker-engine docker.io containerd runc
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent oftware-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install -y docker-ce docker-ce-cli containerd.io

sudo curl -L "https://github.com/docker/compose/releases/download/1.27.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R

# Keybase
curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
sudo apt install -y ./keybase_amd64.deb
run_keybase

# qBittorrent-enhanced
sudo add-apt-repository -y ppa:poplite/qbittorrent-enhanced
sudo apt-get install -y qbittorrent-enhanced qbittorrent-enhanced-nox

# Spotify
curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add - 
curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt install -y spotify-client

# Typora
wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -
sudo add-apt-repository -y 'deb https://typora.io/linux ./'
sudo apt install -y typora

echo "=============================="
echo "Done!"
echo "=============================="
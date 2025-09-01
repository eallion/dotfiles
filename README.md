# My dotfiles

My dotfiles, keep it simple.

### Setup

#### 方法一：通过 curl 直接安装

**安装 Bash 配置：**

```bash
curl -sSL https://s.e5n.cc/dotfiles | bash
# 或
curl -sSL https://s.e5n.cc/dotfiles | sh
```

**安装 Zsh 配置：**

```bash
curl -sSL https://s.e5n.cc/dotfiles | zsh
# 或指定参数
curl -sSL https://s.e5n.cc/dotfiles | bash -s -- zsh
```

#### 方法二：通过参数指定（推荐）

克隆仓库后运行：

```bash
# 克隆仓库
git clone https://github.com/eallion/dotfiles.git
cd dotfiles

# 安装 bash 配置
./install.sh bash

# 安装 zsh 配置
./install.sh zsh
```

```http
$ curl -I https://s.e5n.cc/dotfiles
HTTP/2 301
content-type: text/html
location: https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/setup.sh
cf-placement: local-LAX
strict-transport-security: max-age=15552000; includeSubDomains; preload
x-content-type-options: nosniff
vary: accept-encoding
nel: {"report_to":"cf-nel","success_fraction":0.0,"max_age":604800}
server: cloudflare
alt-svc: h3=":443"; ma=86400
```

#### 功能特性

**共同特性：**
- sudo 免密码配置
- 安装 [Starship](https://starship.rs/)
- 配置 [Starship](https://starship.rs/) [Gruvbox Rainbow Preset](https://starship.rs/presets/gruvbox-rainbow)
- 可选安装 Git 配置 (.gitconfig)
- 可选安装 Alacritty 终端配置
- 可选安装 Kitty 终端配置

**Bash 特性：**
- 安装 [oh-my-bash](https://github.com/ohmybash/oh-my-bash)
- 下载并替换 `.bashrc`
- 下载并替换 `.bash_aliases`
- 安装依赖工具：trash-cli, ripgrep, fd-find

**Zsh 特性：**
- 安装 [oh-my-zsh](https://ohmyzsh.github.io/)
- 安装插件：zsh-autosuggestions, fast-syntax-highlighting, zsh-history-substring-search
- 安装依赖工具：eza, bat, fzf, zoxide, ripgrep, fd-find, gh
- 下载并替换 `.zshrc`
- 创建自定义别名文件 `.oh-my-zsh/custom/aliases.zsh`

# Tips

### Install oh-my-bash

> https://github.com/ohmybash/oh-my-bash

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.bashrc -o "$HOME/.bashrc"
```

### Install Starship

> [Gruvbox Rainbow Preset](https://starship.rs/presets/gruvbox-rainbow)

```bash
curl -sS https://starship.rs/install.sh | sh
starship preset gruvbox-rainbow -o ~/.config/starship.toml
sed -i '1s/^/eval "$(starship init bash)"\n/' ~/.bashrc
source ~/.bashrc
```

### Install JetBrains Maple Mono

> https://github.com/SpaceTimee/Fusion-JetBrainsMapleMono

```bash
wget https://github.com/SpaceTimee/Fusion-JetBrainsMapleMono/releases/latest/download/JetBrainsMapleMono-NF-XX-XX.zip
unzip JetBrainsMapleMono-NF-XX-XX.zip
mkdir -p ~/.fonts
mv *.ttf ~/.fonts/
rm JetBrainsMapleMono-NF-XX-XX.zip LICENSE.txt
fc-cache -f -v
```

### Install Smiley Sans

> https://github.com/atelier-anchor/smiley-sans

```bash
wget https://github.com/atelier-anchor/smiley-sans/releases/download/v2.0.1/smiley-sans-v2.0.1.zip
unzip smiley-sans-v2.0.1.zip
mkdir -p ~/.fonts
mv SmileySans-* ~/.fonts
rm smiley-sans-v2.0.1.zip
fc-cache -f -v
```

### Install Fcitx5-rime

> https://github.com/fcitx/fcitx5-rime

```bash
sudo apt install fcitx5 fcitx5-rime fcitx5-configtool fcitx5-chinese-addons fcitx5-frontend-all im-config

git clone https://github.com/rime/plum.git
cd plum
rime_frontend=fcitx5-rime bash rime-install --select :all lotem/rime-forge/lotem-packages.conf
# pick: 16 21 12 .

fcitx5-configtool

# Add 中州韵
# Customize

wget https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.local/share/fcitx5/rime/custom_phrase.txt -O ~/.local/share/fcitx5/rime/custom_phrase.txt
wget https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.local/share/fcitx5/rime/default.custom.yaml -O ~/.local/share/fcitx5/rime/default.custom.yaml
wget https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.local/share/fcitx5/rime/wubi_pinyin.custom.yaml -O ~/.local/share/fcitx5/rime/wubi_pinyin.custom.yaml

# Redeploy Rime

# Install Kimpanel: https://extensions.gnome.org/extension/261/kimpanel
```

### Install Docker

> https://docs.docker.com/engine/install/ubuntu/

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

sudo systemctl disable docker.service
sudo systemctl disable docker.socket
sudo systemctl disable containerd.service
```

### Install NVM

> https://github.com/nvm-sh/nvm  
> nodejs-lts, npm, pnpm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

nvm install --lts
npm i -g pnpm
```


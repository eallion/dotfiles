# My dotfiles

My dotfiles, keep it simple.

### Setup

#### 方法一：通过 curl 直接安装

**安装 Bash 配置（适用于服务器）：**

```bash
curl -sSL https://s.e5n.cc/dotfiles | bash
# 或
curl -sSL https://s.e5n.cc/dotfiles | sh
```

**安装 Zsh 配置（适用于桌面/开发环境）：**

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

#### 功能特性

**共同特性：**
- **统一别名管理**：`~/.aliases` 跨 Shell 共享，一致的操作体验。
- **现代化工具链**：集成 `eza` (Better ls), `bat` (Better cat), `btop`, `zoxide` (Smart cd)。
- **安全防护**：`mv`/`cp`/`rm` 增加安全提示，`rm` 自动关联 `trash-cli`。
- sudo 免密码配置 (可选)。
- 安装 [Starship](https://starship.rs/) 及 [Gruvbox Rainbow Preset](https://starship.rs/presets/gruvbox-rainbow)。
- 可选安装 Git, Alacritty, Kitty 配置。

**ZSH 特性 (Desktop/Dev)：**
- **Zinit 引擎**：使用最快的 Zinit 插件管理器，极速启动。
- **Modern Experience**：
    - **FZF-Tab**：实时预览补全内容 (ls, ps, kill, docker 等)。
    - **Alias Tip**：当你输入长命令时提醒你使用别名 (`zsh-you-should-use`)。
- **Turbo Mode**：`nvm`, `docker`, `gh` 等重型插件延迟加载，不拖慢启动。
- **Plugins**：`zsh-autosuggestions`, `fast-syntax-highlighting`, `history-substring-search`, `extract`, `sudo` 等。

**Bash 特性 (Server)：**
- **Oh My Bash**：轻量级管理。
- **Lazy Load**：`nvm`/`node`/`npm` 仅在首次使用时加载，确保秒开。
- **工具对齐**：服务器环境同样配置了 `eza`, `bat`, `fzf` 等工具，保持与 Zsh 一致的手感。

---

# Tips

以下内容由 `setup.sh` 自动处理，仅供参考。

### Install oh-my-bash

> https://github.com/ohmybash/oh-my-bash

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.bashrc -o "$HOME/.bashrc"
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

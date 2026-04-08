# My dotfiles

My dotfiles, keep it simple.

### Setup

#### 方法一：通过 curl 直接安装

**安装 Bash 配置（适用于服务器）：**

```bash
curl -sSL https://s.e5n.cc/dotfiles | bash -s -- bash
```

**安装 Zsh 配置：**

```bash
curl -sSL https://s.e5n.cc/dotfiles | bash -s -- zsh
```

**安装 Fish 配置（适用于桌面/开发环境）：**

```bash
# sudo apt update && sudo apt install -y fish
# chsh -s /usr/bin/fish

curl -sSL https://s.e5n.cc/dotfiles | bash -s -- fish
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

# 安装 fish 配置
./install.sh fish
```

#### 安装模式

可以通过第二个参数指定安装模式，自动化安装流程：

```bash
# 最小模式：仅安装 Shell 配置，跳过所有工具安装
./install.sh bash --minimal

# 完整模式：安装所有工具和配置，无需交互
./install.sh fish --full

# 服务器模式：安装服务器常用工具（curl/wget/git），跳过 GUI 相关
./install.sh bash --server

# 桌面模式：安装完整工具链 + 字体，适合开发环境
./install.sh fish --desktop
```

| 模式 | 基础工具 | CLI 工具 | Starship | 字体 | 交互 |
|------|----------|----------|----------|------|------|
| `--minimal` | ❌ | ❌ | ❌ | ❌ | 无 |
| `--full` | ✅ 全部 | ✅ 全部 | ✅ | ✅ | 无 |
| `--server` | ✅ 基础 | ✅ 交互 | ✅ | ❌ | 部分 |
| `--desktop` | ✅ 全部 | ✅ 全部 | ✅ | ✅ | 无 |
| 不指定 | 交互选择 | 交互选择 | 交互选择 | 交互选择 | 完全交互 |

#### 回滚配置

如果安装后需要恢复之前的配置：

```bash
# 回滚到安装前的配置
./install.sh --rollback
```

备份文件保存在 `~/.config/dotfiles/` 目录下，每次安装会创建带时间戳的备份。

#### 清除备份

如果不再需要备份文件，可以清除所有备份：

```bash
# 清除所有备份
./install.sh --clean-backup
```

#### 功能特性

**共同特性：**

- **统一别名管理**：`~/.aliases` 跨 Shell 共享，一致的操作体验。
- **现代化工具链**：集成 `eza` (Better ls), `bat` (Better cat), `btop`, `zoxide` (Smart cd)。
- **安全防护**：`mv`/`cp`/`rm` 增加安全提示，`rm` 自动关联 `trash-cli`。
- sudo 免密码配置 (可选)。
- 安装 [Starship](https://starship.rs/) 及 [Gruvbox Rainbow Preset](https://starship.rs/presets/gruvbox-rainbow)。
- 可选安装 Git, Kitty 配置。

**Bash 特性 (Server)：**

- **Oh My Bash**：轻量级管理。
- **Lazy Load**：`nvm`/`node`/`npm` 仅在首次使用时加载，确保秒开。
- **工具对齐**：服务器环境同样配置了 `eza`, `bat`, `fzf` 等工具，保持与桌面一致的手感。

**Fish 特性 (Desktop/Dev)：**

- **原生配置**：使用 `~/.config/fish/config.fish` 和 `functions` 目录管理配置。
- **现代工具链**：同样接入 `starship`, `zoxide`, `fzf`, `mise`, `eza`, `bat`。
- **别名迁移**：把常用别名翻译成 Fish 函数和 `abbr`，保留原有使用习惯。

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

### Install Mise

> https://mise.jdx.dev/  
> Dev tools manager (Node.js, Python, etc.)

```bash
# APT 安装
sudo apt-get update -y && sudo apt-get install -y gpg curl
sudo install -dm 755 /etc/apt/keyrings
curl -fSs https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64,arm64,armhf] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y mise

# 添加到 shell 配置
# Bash:
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
# Zsh:
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
# Fish:
echo 'mise activate fish | source' >> ~/.config/fish/config.fish

# 使用 mise 安装 Node.js 和 pnpm
mise use --global node@lts
mise use --global pnpm@latest
```

### Install Docker

> https://docs.docker.com/engine/install/ubuntu/

```bash
# 使用官方安装脚本
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 添加用户到 docker 组
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# 配置 Docker 服务（可选）
sudo systemctl disable docker.service
sudo systemctl disable docker.socket
sudo systemctl disable containerd.service
```

### Install UFW

> https://help.ubuntu.com/community/UFW

```bash
# 安装 UFW
sudo apt-get install -y ufw

# 配置默认策略
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 允许 SSH
sudo ufw allow ssh

# 启用 UFW
sudo ufw --force enable

# 查看状态
sudo ufw status
```

### Install UFW Docker

> https://github.com/chaifeng/ufw-docker

```bash
# 下载 ufw-docker 脚本
sudo wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
sudo chmod +x /usr/local/bin/ufw-docker

# 配置 UFW Docker 规则
sudo tee -a /etc/ufw/after.rules > /dev/null <<EOF

# ufw-docker
*filter
:ufw-user-forward - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j UFW-USER-FORWARD
-A UFW-USER-FORWARD -j RETURN -s 10.0.0.0/8
-A UFW-USER-FORWARD -j RETURN -s 172.16.0.0/12
-A UFW-USER-FORWARD -j RETURN -s 192.168.0.0/16
-A UFW-USER-FORWARD -p tcp -d 127.0.0.1 --dport 2375 -j RETURN
-A UFW-USER-FORWARD -p tcp -d 127.0.0.1 --dport 2376 -j RETURN
COMMIT
EOF

# 重新加载 UFW
sudo ufw reload

# 使用示例
ufw-docker allow nginx
ufw-docker allow mysql
```

### Install Ghostty

> https://ghostty.org/

```bash
# 下载并安装 Ghostty (根据你的系统选择合适的包)
# Ubuntu/Debian:
curl -fsSL https://github.com/ghostty-org/ghostty/releases/latest/download/ghostty_amd64.deb -o ghostty.deb
sudo dpkg -i ghostty.deb

# 或者从源码编译 (需要 Go)
git clone https://github.com/ghostty-org/ghostty
cd ghostty
sudo apt install libgtk-4-dev libadwaita-1-dev
go build -o ghostty ./cmd/ghostty

# 配置 Ghostty
mkdir -p ~/.config/ghostty

# 下载配置文件
curl -fsSL https://raw.githubusercontent.com/eallion/dotfiles/main/.config/ghostty/config.ghostty -o ~/.config/ghostty/config.ghostty
curl -fsSL https://raw.githubusercontent.com/eallion/dotfiles/main/.config/ghostty/auto/theme.ghostty -o ~/.config/ghostty/auto/theme.ghostty
```

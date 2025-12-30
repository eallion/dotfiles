#!/bin/bash
#
# 自适应 Shell 环境配置脚本，支持 bash 和 zsh
# 自动检测执行脚本的 shell 并安装相应配置
#
set -e

# 优先检查显式传递的参数
if [[ -n "$1" ]]; then
    if [[ "$1" == "zsh" ]]; then
        INSTALL_SHELL="zsh"
    elif [[ "$1" == "bash" ]]; then
        INSTALL_SHELL="bash"
    else
        echo "⚠ 未知参数: $1，将尝试自动检测..."
    fi
fi

# 如果未通过参数指定，则尝试检测
if [[ -z "$INSTALL_SHELL" ]]; then
    # 尝试使用 ps 检测 (需处理 ps 命令不存在的情况)
    if command -v ps &> /dev/null; then
        if CURRENT_SHELL=$(ps -p $$ -o comm= 2>/dev/null); then
            DETECTED_SHELL=$(basename "$CURRENT_SHELL")
        else
            DETECTED_SHELL="unknown"
        fi
    else
        DETECTED_SHELL="unknown"
    fi

    echo "▶ 自动检测到的 Shell: $DETECTED_SHELL"

    if [[ "$DETECTED_SHELL" == "zsh" ]]; then
        INSTALL_SHELL="zsh"
    elif [[ "$DETECTED_SHELL" == "bash" || "$DETECTED_SHELL" == "sh" ]]; then
        # 即使在 bash/sh 下运行，也检查 $0 是否暗示了 zsh (虽然前面 $1 已经检查过了，这里保留作为 fallback)
        if [[ "$0" == "zsh" ]]; then
            INSTALL_SHELL="zsh"
        else
            INSTALL_SHELL="bash"
        fi
    else
        # 无法检测且未指定参数，默认为 bash
        echo "⚠ 无法检测到 Shell 类型 (可能缺少 ps 命令)，且未指定参数。"
        echo "⚠ 默认使用 bash 安装。"
        INSTALL_SHELL="bash"
    fi
fi

echo "=== 正在开始配置 $INSTALL_SHELL 环境 ==="
echo "脚本将自动备份你的配置文件"
echo "------------------------------"

cd ~

echo "------------------------------"

# --- 备份文件 ---
printf "是否备份现有的配置文件 (.zshrc, .bashrc 等)? (y/N) "
if read -t 10 BACKUP_FILES < /dev/tty; then :; else BACKUP_FILES="N"; echo ""; fi

if [[ "$BACKUP_FILES" =~ ^[Yy]$ ]]; then
    # 备份现有的配置文件
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    backup_files=(
        ".bashrc"
        ".bash_aliases"
        ".zshrc"
        ".gitconfig"
        ".p10k.zsh"
    )

    for file in "${backup_files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            mv "$HOME/$file" "$HOME/${file}.bak_$TIMESTAMP"
            echo "✔ 备份 ~/$file 为 ~/${file}.bak_$TIMESTAMP"
        fi
    done
else
    echo "⏭ 跳过备份。"
fi
echo "------------------------------"

# --- 检查用户类型并设置安装逻辑 ---
if [[ "$EUID" -eq 0 ]]; then
    echo "▶ 检测到当前用户为 root。所有安装命令将直接运行。"
    SUDO=""
else
    # 检查 sudo 是否安装
    if ! command -v sudo &> /dev/null; then
        echo "❌ 未检测到 sudo 命令。"
        echo "你需要安装 sudo 才能继续。"
        printf "是否尝试使用 su 切换到 root 自动安装 sudo？(y/N) "
        if read -t 10 INSTALL_SUDO < /dev/tty; then :; else INSTALL_SUDO="N"; echo ""; fi
        if [[ "$INSTALL_SUDO" =~ ^[Yy]$ ]]; then
            echo "请输入 root 密码以继续："
            su -c "apt-get update && apt-get install -y sudo"
            if ! command -v sudo &> /dev/null; then
                echo "❌ sudo 安装失败。请手动解决或以 root 运行。"
                exit 1
            fi
        else
            echo "请手动安装 sudo (apt install sudo) 或以 root 运行此脚本。"
            exit 1
        fi
    fi

    # 检查当前用户是否在 sudoers 中
    if ! sudo -v &> /dev/null; then
        echo "❌ 当前用户似乎没有 sudo 权限。"
        printf "是否尝试使用 su 切换到 root 将当前用户加入 sudoers？(y/N) "
        if read -t 10 ADD_SUDOER < /dev/tty; then :; else ADD_SUDOER="N"; echo ""; fi
        if [[ "$ADD_SUDOER" =~ ^[Yy]$ ]]; then
            CURRENT_USER=$(whoami)
            echo "请输入 root 密码以继续："
            su -c "usermod -aG sudo $CURRENT_USER || echo '$CURRENT_USER ALL=(ALL) ALL' >> /etc/sudoers"
            echo "✔ 已尝试将用户加入 sudoers。你需要重新登录或重新运行脚本以生效。"
            exit 0
        else
            echo "请手动将当前用户加入 sudoers 或以 root 运行此脚本。"
            exit 1
        fi
    fi

    echo "▶ 检测到当前为普通用户。安装命令将使用 sudo 运行。"
    SUDO="sudo"

    echo "▶ 正在配置 sudo 免密码..."
    CURRENT_USER=$(whoami)
    # 尝试配置免密
    if echo "$CURRENT_USER ALL=(ALL) NOPASSWD:ALL" | $SUDO tee /etc/sudoers.d/90-$CURRENT_USER > /dev/null; then
        echo "✔ sudo 免密码配置成功！"
    else
        echo "⚠ sudo 免密码配置失败，脚本将继续运行，后续可能需要手动输入密码。"
    fi
fi
echo "------------------------------"

# --- 更新包管理器与安装基础工具 ---
printf "是否更新软件源并安装基础工具 (curl, wget, git, jq, neovim)? (y/N) "
if read -t 10 INSTALL_BASICS < /dev/tty; then :; else INSTALL_BASICS="N"; echo ""; fi

if [[ "$INSTALL_BASICS" =~ ^[Yy]$ ]]; then
    # --- 更新包管理器 ---
    echo "▶ 正在更新包管理器..."
    $SUDO apt-get update
    echo "✔ 包管理器更新完成"

    # --- 安装必须的基本工具 ---
    echo "▶ 正在安装必须的基本工具..."
    $SUDO apt-get install -y curl wget git ca-certificates jq neovim
    echo "✔ 基本工具安装完成"
else
    echo "⏭ 跳过基础工具安装。"
fi
echo "------------------------------"

# --- [新增] 如果目标 shell 是 zsh，优先安装 zsh ---
if [[ "$INSTALL_SHELL" == "zsh" ]]; then
    printf "是否安装 ZSH (作为目标 Shell)? (y/N) "
    if read -t 10 INSTALL_ZSH_CORE < /dev/tty; then :; else INSTALL_ZSH_CORE="N"; echo ""; fi

    if [[ "$INSTALL_ZSH_CORE" =~ ^[Yy]$ ]]; then
        echo "▶ 正在优先确保 ZSH 已安装..."
        if ! command -v zsh &> /dev/null; then
            $SUDO apt-get install -y zsh
            echo "✔ ZSH 安装成功！"
        else
            echo "✔ ZSH 已经安装。"
        fi
    else
        echo "⏭ 跳过 ZSH 安装。"
    fi
    echo "------------------------------"
fi

# --- 安装 Starship ---
printf "是否安装 Starship 及其配置? (y/N) "
if read -t 10 INSTALL_STARSHIP < /dev/tty; then :; else INSTALL_STARSHIP="N"; echo ""; fi

if [[ "$INSTALL_STARSHIP" =~ ^[Yy]$ ]]; then
    echo "▶ 正在安装 Starship..."
    if ! command -v starship &> /dev/null; then
        STARSHIP_INSTALL_YES=true curl -sS https://starship.rs/install.sh | sh
        echo "✔ Starship 安装成功！"
    else
        echo "✔ Starship 已经安装，跳过安装。"
    fi
    echo "------------------------------"

    # --- 配置 Starship ---
    echo "▶ 正在配置 Starship ..."
    mkdir -p ~/.config
    curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.config/starship.toml -o "$HOME/.config/starship.toml"
    echo "✔ Starship 配置成功！"
else
    echo "⏭ 跳过 Starship 安装与配置。"
fi
echo "------------------------------"

# --- 安装字体 ---
printf "是否安装 JetBrains Maple Mono 字体? (y/N) "
if read -t 10 INSTALL_FONTS < /dev/tty; then :; else INSTALL_FONTS="N"; echo ""; fi

if [[ "$INSTALL_FONTS" =~ ^[Yy]$ ]]; then
    echo "▶ 正在安装 JetBrains Maple Mono 字体..."
    wget https://github.com/SpaceTimee/Fusion-JetBrainsMapleMono/releases/latest/download/JetBrainsMapleMono-NF-XX-XX-XX.zip
    unzip -o JetBrainsMapleMono-NF-XX-XX-XX.zip
    mkdir -p ~/.fonts
    mv *.ttf ~/.fonts/
    rm JetBrainsMapleMono-NF-XX-XX-XX.zip LICENSE.txt
    if command -v fc-cache &> /dev/null; then
        fc-cache -f -v
    fi
    echo "✔ JetBrains Maple Mono 字体安装成功！"
else
    echo "⏭ 跳过字体安装。"
fi
echo "------------------------------"

# 根据 shell 类型执行相应安装
if [[ "$INSTALL_SHELL" == "zsh" ]]; then
    echo "=== 开始安装 ZSH 配置 ==="

    # 安装 ZSH
    # 安装 ZSH
    echo "▶ 正在安装 ZSH..."
    if ! command -v zsh &> /dev/null; then
        $SUDO apt-get install -y zsh
        echo "✔ ZSH 安装成功！"
    else
        echo "✔ ZSH 已经安装，跳过安装。"
    fi
    echo "------------------------------"

    # --- [可选] 安装 Zsh 现代 CLI 工具 ---
    printf "是否安装现代 CLI 工具 (eza, bat, fzf, zoxide, btop, gh 等)? (y/N) "
    if read -t 10 INSTALL_ZSH_CLI_TOOLS < /dev/tty; then :; else INSTALL_ZSH_CLI_TOOLS="N"; echo ""; fi

    if [[ "$INSTALL_ZSH_CLI_TOOLS" =~ ^[Yy]$ ]]; then
        echo "▶ 正在安装 ZSH 插件依赖工具..."
        $SUDO apt-get install -y \
            unzip \
            eza \
            bat \
            fzf \
            zoxide \
            ripgrep \
            fd-find \
            gh \
            trash-cli \
            btop || echo "⚠ 部分工具安装失败，可能仓库中不存在 (如 eza)，脚本将继续。"

        # 创建 fd 符号链接（ Debian/Ubuntu 中是 fd-find ）
        if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
            $SUDO ln -s $(which fdfind) /usr/local/bin/fd
        fi
    else
        echo "⏭ 跳过现代 CLI 工具安装。"
    fi
    echo "------------------------------"

    # --- 安装 ZSH 配置文件 ---
    printf "是否安装 ZSH 配置文件 (.zshrc, .aliases, .login_info.sh)? (y/N) "
    if read -t 10 INSTALL_ZSH_CONFIG < /dev/tty; then :; else INSTALL_ZSH_CONFIG="N"; echo ""; fi

    if [[ "$INSTALL_ZSH_CONFIG" =~ ^[Yy]$ ]]; then
        # 创建自定义别名文件
        echo "▶ 正在配置 ZSH 自定义别名..."
        # 下载 .aliases
        curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.aliases -o "$HOME/.aliases"

        echo "✔ ZSH 自定义别名创建完成（.aliases）！"

        # [新增] 如果安装了 neovim，添加别名
        if command -v nvim &> /dev/null; then
            echo "alias vim='nvim'" >> "$HOME/.aliases"
            echo "✔ 已添加 alias vim=nvim 到 .aliases"
        fi
        echo "------------------------------"

        # 下载并替换 .zshrc
        echo "▶ 正在下载 .zshrc..."
        curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.zshrc -o "$HOME/.zshrc"
        
        # 下载 login_info.sh
        echo "▶ 正在下载 login_info.sh..."
        curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.login_info.sh -o "$HOME/.login_info.sh"
        
        echo "✔ ZSH 配置已安装。"
    else
        echo "⏭ 跳过 ZSH 配置文件安装。"
    fi
    echo "------------------------------"

else
    echo "=== 开始安装 BASH 配置 ==="

    # --- [可选] 安装 Oh My Bash ---
    printf "是否安装 Oh My Bash 框架? (y/N) "
    if read -t 10 INSTALL_OMB < /dev/tty; then :; else INSTALL_OMB="N"; echo ""; fi

    if [[ "$INSTALL_OMB" =~ ^[Yy]$ ]]; then
        echo "▶ 正在安装 Oh My Bash..."
        if [ ! -d "$HOME/.oh-my-bash" ]; then
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
            echo "✔ Oh My Bash 安装成功！"
        else
            echo "✔ Oh My Bash 已经安装，跳过安装。"
        fi

        # 创建 Oh My Bash starship 插件
        echo "▶ 正在配置 Oh My Bash starship 插件..."
        mkdir -p ~/.oh-my-bash/custom/plugins/starship
        cat > ~/.oh-my-bash/custom/plugins/starship/starship.plugin.sh << 'EOF'
#!/bin/bash

# Starship prompt for Oh My Bash
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi
EOF
        echo "✔ Oh My Bash starship 插件配置完成！"
    else
        echo "⏭ 跳过 Oh My Bash 安装。"
    fi
    echo "------------------------------"

    # --- [可选] 安装 Bash 现代 CLI 工具 ---
    printf "是否安装现代 CLI 工具 (eza, bat, fzf, zoxide, btop, gh 等)? (y/N) "
    if read -t 10 INSTALL_BASH_CLI_TOOLS < /dev/tty; then :; else INSTALL_BASH_CLI_TOOLS="N"; echo ""; fi

    if [[ "$INSTALL_BASH_CLI_TOOLS" =~ ^[Yy]$ ]]; then
        echo "▶ 正在安装 Bash 依赖工具..."
        $SUDO apt-get install -y \
            trash-cli \
            ripgrep \
            fd-find \
            eza \
            bat \
            fzf \
            zoxide \
            gh \
            btop || echo "⚠ 部分工具安装失败，可能仓库中不存在 (如 eza)，脚本将继续。"

        # 创建 fd 符号链接
        if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
            $SUDO ln -s $(which fdfind) /usr/local/bin/fd
        fi
    else
        echo "⏭ 跳过现代 CLI 工具安装。"
    fi
    echo "------------------------------"

    # --- 安装 Bash 配置文件 ---
    printf "是否安装 Bash 配置文件 (.bashrc, .aliases, .login_info.sh)? (y/N) "
    if read -t 10 INSTALL_BASH_CONFIG < /dev/tty; then :; else INSTALL_BASH_CONFIG="N"; echo ""; fi

    if [[ "$INSTALL_BASH_CONFIG" =~ ^[Yy]$ ]]; then
        # 下载并替换自定义点文件
        echo "▶ 正在下载 .bashrc .aliases .login_info.sh..."
        curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.bashrc -o "$HOME/.bashrc"
        curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.aliases -o "$HOME/.aliases"
        curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.login_info.sh -o "$HOME/.login_info.sh"
        
        # [新增] 如果安装了 neovim，添加别名
        if command -v nvim &> /dev/null; then
            echo "alias vim='nvim'" >> "$HOME/.aliases"
            echo "✔ 已添加 alias vim=nvim 到 .aliases"
        fi
        
        echo "✔ Bash 配置已安装。"
    else
        echo "⏭ 跳过 Bash 配置文件安装。"
    fi
    echo "------------------------------"
fi

# --- 安装 NVM ---
printf "是否安装 NVM (Node Version Manager)? (y/N) "
if read -t 10 INSTALL_NVM < /dev/tty; then :; else INSTALL_NVM="N"; echo ""; fi

if [[ "$INSTALL_NVM" =~ ^[Yy]$ ]]; then
    echo "▶ 正在安装 NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    
    echo "▶ 正在安装 Node.js LTS..."
    nvm install --lts
    echo "▶ 正在安装 pnpm..."
    npm i -g pnpm
    
    echo "✔ NVM 安装完成！"
else
    echo "⏭ 跳过 NVM 安装。"
fi
echo "------------------------------"

# --- 下载其他配置文件 ---
echo "▶ 正在配置其他配置文件..."

# Git 配置
printf "是否安装 Git 配置 (.gitconfig)? (y/N) "
if read -t 10 INSTALL_GIT_CONFIG < /dev/tty; then :; else INSTALL_GIT_CONFIG="N"; echo ""; fi

if [[ "$INSTALL_GIT_CONFIG" =~ ^[Yy]$ ]]; then
    echo "▶ 正在配置 Git 配置..."
    curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.gitconfig -o "$HOME/.gitconfig"
    echo "✔ Git 配置已安装。"
else
    echo "⏭ 跳过 Git 配置。"
fi

# Alacritty 配置
printf "是否安装 Alacritty 配置 (github_dark_dimmed.toml, alacritty.toml)? (y/N) "
if read -t 10 INSTALL_ALACRITTY < /dev/tty; then :; else INSTALL_ALACRITTY="N"; echo ""; fi
if [[ "$INSTALL_ALACRITTY" =~ ^[Yy]$ ]]; then
    echo "▶ 正在下载 Alacritty 配置..."
    mkdir -p "$HOME/.config/alacritty/themes/themes"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.config/alacritty/themes/themes/github_dark_dimmed.toml -o "$HOME/.config/alacritty/themes/themes/github_dark_dimmed.toml"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.config/alacritty/alacritty.toml -o "$HOME/.config/alacritty/alacritty.toml"
    echo "✔ Alacritty 配置已安装。"
else
    echo "⏭ 跳过 Alacritty 配置。"
fi

# Kitty 配置
printf "是否安装 Kitty 配置 (current-theme.conf, kitty.conf)? (y/N) "
if read -t 10 INSTALL_KITTY < /dev/tty; then :; else INSTALL_KITTY="N"; echo ""; fi
if [[ "$INSTALL_KITTY" =~ ^[Yy]$ ]]; then
    echo "▶ 正在下载 Kitty 配置..."
    mkdir -p "$HOME/.config/kitty"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.config/kitty/current-theme.conf -o "$HOME/.config/kitty/current-theme.conf"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/.config/kitty/kitty.conf -o "$HOME/.config/kitty/kitty.conf"
    echo "✔ Kitty 配置已安装。"
else
    echo "⏭ 跳过 Kitty 配置。"
fi

# Docker 守护进程配置
printf "是否配置 Docker 守护进程 (daemon.json)? (y/N) "
if read -t 10 INSTALL_DOCKER_CONFIG < /dev/tty; then :; else INSTALL_DOCKER_CONFIG="N"; echo ""; fi

if [[ "$INSTALL_DOCKER_CONFIG" =~ ^[Yy]$ ]]; then
    echo "▶ 正在配置 Docker 守护进程..."
    $SUDO mkdir -p /etc/docker
    DAEMON_JSON_URL="https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/etc/docker/daemon.json"
    TEMP_JSON=$(mktemp)

    if curl -sSL "$DAEMON_JSON_URL" -o "$TEMP_JSON"; then
        if [ -f "/etc/docker/daemon.json" ]; then
            echo "ℹ 发现现有 daemon.json，正在合并配置..."
            # 使用 jq 合并配置 (现有配置 * 远程配置 = 远程覆盖现有)
            # 注意: 这里的 merge 策略是远程覆盖本地冲突项，但保留本地独有项
            $SUDO jq -s '.[0] * .[1]' /etc/docker/daemon.json "$TEMP_JSON" | $SUDO tee "$TEMP_JSON.merged" > /dev/null
            $SUDO mv "$TEMP_JSON.merged" /etc/docker/daemon.json
        else
            echo "ℹ 未发现 daemon.json，正在创建..."
            $SUDO mv "$TEMP_JSON" /etc/docker/daemon.json
            $SUDO chmod 644 /etc/docker/daemon.json
        fi
        echo "✔ Docker 守护进程配置已更新。"
    else
        echo "⚠ 无法下载 Docker 配置，跳过。"
    fi
    rm -f "$TEMP_JSON"
else
    echo "⏭ 跳过 Docker 配置。"
fi

echo "------------------------------"
echo "=== 配置完成！==="
echo "请重启你的终端或运行以下命令以应用所有更改："

if [[ "$INSTALL_SHELL" == "zsh" ]]; then
    echo "source ~/.zshrc"
    echo ""
    echo "💡 提示：如果你想让 ZSH 成为默认 shell，请运行："
    echo "chsh -s \$(which zsh)"
else
    echo "source ~/.bashrc"
fi

echo ""
echo "🎉 $INSTALL_SHELL 环境配置完成！"
#!/bin/bash
#
# 自适应 Shell 环境配置脚本，支持 bash 和 zsh
# 自动检测执行脚本的 shell 并安装相应配置
#
set -e

# 检测执行脚本的 shell
CURRENT_SHELL=$(ps -p $$ -o comm=)
DETECTED_SHELL=$(basename "$CURRENT_SHELL")

# 如果通过 curl 方式执行，检查参数或使用默认值
if [[ "$DETECTED_SHELL" == "bash" || "$DETECTED_SHELL" == "sh" ]]; then
    if [[ "$0" == "zsh" || "$1" == "zsh" ]]; then
        INSTALL_SHELL="zsh"
    else
        INSTALL_SHELL="bash"
    fi
elif [[ "$DETECTED_SHELL" == "zsh" ]]; then
    INSTALL_SHELL="zsh"
else
    echo "❌ 无法检测到支持的 shell 类型 (bash/zsh)"
    exit 1
fi

echo "=== 正在开始配置 $INSTALL_SHELL 环境 ==="
echo "脚本将自动备份你的配置文件"
echo "------------------------------"

cd ~

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
        read -t 10 -p "是否尝试使用 su 切换到 root 自动安装 sudo？(y/N) " INSTALL_SUDO || INSTALL_SUDO="N"
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
        read -t 10 -p "是否尝试使用 su 切换到 root 将当前用户加入 sudoers？(y/N) " ADD_SUDOER || ADD_SUDOER="N"
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

# --- 更新包管理器 ---
echo "▶ 正在更新包管理器..."
$SUDO apt-get update
echo "✔ 包管理器更新完成"
echo "------------------------------"

# --- 安装基本工具 ---
echo "▶ 正在安装基本工具..."
$SUDO apt-get install -y curl wget git ca-certificates build-essential
echo "✔ 基本工具安装完成"
echo "------------------------------"

# --- 安装 Starship ---
echo "▶ 正在安装 Starship..."
if ! command -v starship &> /dev/null; then
    STARSHIP_INSTALL_YES=true curl -sS https://starship.rs/install.sh | sh
    echo "✔ Starship 安装成功！"
else
    echo "✔ Starship 已经安装，跳过安装。"
fi
echo "------------------------------"

# --- 配置 Starship ---
echo "▶ 正在配置 Starship 预设..."
mkdir -p ~/.config
starship preset gruvbox-rainbow -o ~/.config/starship.toml
echo "✔ Starship 预设配置成功！"
echo "------------------------------"

# 根据 shell 类型执行相应安装
if [[ "$INSTALL_SHELL" == "zsh" ]]; then
    echo "=== 开始安装 ZSH 配置 ==="

    # 安装 ZSH
    echo "▶ 正在安装 ZSH..."
    if ! command -v zsh &> /dev/null; then
        $SUDO apt-get install -y zsh
        echo "✔ ZSH 安装成功！"
    else
        echo "✔ ZSH 已经安装，跳过安装。"
    fi
    echo "------------------------------"

    # 安装 Oh My Zsh
    echo "▶ 正在安装 Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        echo "✔ Oh My Zsh 安装成功！"
    else
        echo "✔ Oh My Zsh 已经安装，跳过安装。"
    fi
    echo "------------------------------"

    # 安装 ZSH 插件所需的工具
    echo "▶ 正在安装 ZSH 插件依赖工具..."
    $SUDO apt-get install -y \
        curl \
        wget \
        unzip \
        eza \
        bat \
        fzf \
        zoxide \
        ripgrep \
        fd-find \
        gh \
        npm

    # 安装额外需要的工具
    # 确保已经安装了基础构建工具
    $SUDO apt-get install -y \
        build-essential \
        pkg-config \
        libssl-dev

    # 创建 fd 符号链接（ Debian/Ubuntu 中是 fd-find ）
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        $SUDO ln -s $(which fdfind) /usr/local/bin/fd
    fi

    # 安装 Oh My Zsh 插件
    echo "▶ 正在安装 Oh My Zsh 插件..."

    # zsh-autosuggestions
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    # zsh-syntax-highlighting
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    # fast-syntax-highlighting (替代 zsh-syntax-highlighting)
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]; then
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
    fi

    # zsh-history-substring-search
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-history-substring-search" ]; then
        git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
    fi

    echo "✔ Oh My Zsh 插件安装完成！"
    echo "------------------------------"

    # 创建自定义别名文件
    echo "▶ 正在配置 ZSH 自定义文件..."
    mkdir -p ~/.oh-my-zsh/custom

    # 写入 aliases.zsh
    cat > ~/.oh-my-zsh/custom/aliases.zsh << 'EOF'
mcd() {
  mkdir -p "$1" && cd "$1"
}

gz() {
  tar -czvf "$1.tar.gz" "$1"
}

warn_rm() {
    if command -v trash >/dev/null 2>&1; then
        echo "🚨 警告：rm 功能已禁用！" >&2
        echo " " >&2
        echo "请使用安全的 'trash file' 命令将文件放入回收站。" >&2
        echo "用 '\\rm file' 可强制使用系统 rm 功能。" >&2
        return 1
    else
        echo "🚨 警告：rm 功能已禁用！" >&2
        echo " " >&2
        echo "请安装 'trash-cli' 以使用回收站代替 rm。" >&2
        echo " " >&2
        if command -v apt >/dev/null 2>&1; then
            echo "• sudo apt install trash-cli" >&2
        elif command -v yum >/dev/null 2>&1; then
            echo "• sudo yum install trash-cli" >&2
        elif command -v brew >/dev/null 2>&1; then
            echo "• brew install trash-cli" >&2
        elif command -v pacman >/dev/null 2>&1; then
            echo "• sudo pacman -S trash-cli" >&2
        else
            echo "请前往 https://github.com/andreafrancia/trash-cli 安装 'trash-cli' 。" >&2
        fi
        echo " " >&2
        echo "用 '\\rm file' 可强制使用系统 rm 功能。" >&2
        return 1
    fi
}
alias rm='warn_rm'
alias kssh="kitten ssh"
alias icat="kitten icat"
alias c=clear
alias cp="cp -iv"
alias up="sudo apt update && sudo apt upgrade -y && sudo apt autoremove && sudo apt autoclean && flatpak update -y"
alias python="python3"
alias sqlite="sqlite3"
alias ugz='tar -xzvf'
alias grep='rg'

# Docker Alias
alias d='docker'
alias dps='docker ps -a'
alias dpsa='docker ps -a'
alias dim='docker images'
alias dexec='docker exec -it'
alias dstopall='docker stop $(docker ps -q)'
alias drmall='docker rm -f $(docker ps -aq)'
alias drmi='docker image prune -a'
alias dnetrm='docker network prune'
alias dclean='docker system prune -a'
alias dbuild='docker build --no-cache'
alias dcip='docker inspect --format="{{.NetworkSettings.IPAddress}}" '
alias dlast='docker exec -it $(docker ps -lq) bash'
alias dclogs='docker-compose logs -f'
alias dlogs='docker logs -f'
alias dlf='docker logs -f'
alias dc='docker-compose'
alias dcd='docker compose down'
alias dcdown='docker compose down'
alias dcp='docker compose pull'
alias dcu='docker compose up -d'
alias dcud='docker compose up -d'
alias dcudf='docker compose up -d --force-recreate'
alias dcuf='docker compose up -d --force-recreate'
alias dcup='docker compose up -d'
alias dcupf='docker compose up -d --force-recreate'

# Git Alias
alias g=git
alias ga="git add"
alias gaa="git add --all"
alias gam="git am"
alias gama="git am --abort"
alias gamc="git am --continue"
alias gams="git am --skip"
alias gamscp="git am --show-current-patch"
alias gap="git apply"
alias gapa="git add --patch"
alias gapt="git apply --3way"
alias gau="git add --update"
alias gav="git add --verbose"
alias gb="git branch"
alias gbD="git branch -D"
alias gba="git branch -a"
alias gbd="git branch -d"
alias gbl="git blame -b -w"
alias gbnm="git branch --no-merged"
alias gbr="git branch --remote"
alias gbs="git bisect"
alias gbsb="git bisect bad"
alias gbsg="git bisect good"
alias gbsr="git bisect reset"
alias gbss="git bisect start"
alias gc="git commit -v"
alias "gc!"="git commit -v --amend"
alias gca="git commit -v -a"
alias "gca!"="git commit -v -a --amend"
alias gcam="git commit -a -m"
alias "gcan!"="git commit -v -a --no-edit --amend"
alias "gcans!"="git commit -v -a -s --no-edit --amend"
alias gcb="git checkout -b"
alias gcd="git checkout develop"
alias gcf="git config --list"
alias gcl="git clone --recurse-submodules"
alias gclean="git clean -id"
alias gcm="git commit -a -m"
alias gcmsg="git commit -m"
alias "gcn!"="git commit -v --no-edit --amend"
alias gco="git checkout"
alias gcount="git shortlog -sn"
alias gcp="git cherry-pick"
alias gcpa="git cherry-pick --abort"
alias gcpc="git cherry-pick --continue"
alias gcs="git commit -S"
alias gcsm="git commit -s -m"
alias gd="git diff"
alias gdca="git diff --cached"
alias gdcw="git diff --cached --word-diff"
alias gds="git diff --staged"
alias gdt="git diff-tree --no-commit-id --name-only -r"
alias gdw="git diff --word-diff"
alias gf="git fetch"
alias gfa="git fetch --all --prune"
alias gfg="git ls-files | grep"
alias gfo="git fetch origin"
alias gg="git gui citool"
alias gga="git gui citool --amend"
alias ggpur=ggu
alias ghh="git help"
alias gignore="git update-index --assume-unchanged"
alias gignored="git ls-files -v | grep "^[[:lower:]]""
alias gist="nocorrect gist"
alias gk="\gitk --all --branches"
alias gl="git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\""
alias gll="gl -10"
alias glg="git log --stat"
alias glgg="git log --graph"
alias glgga="git log --graph --decorate --all"
alias glgm="git log --graph --max-count=10"
alias glgp="git log --stat -p"
alias glo="git log --oneline --decorate"
alias glod="git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\""
alias glods="git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\" --date=short"
alias glog="git log --oneline --decorate --graph"
alias gloga="git log --oneline --decorate --graph --all"
alias glol="git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\""
alias glola="git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\" --all"
alias glols="git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\" --stat"
alias glp=_git_log_prettily
alias gm="git merge"
alias gma="git merge --abort"
alias gmt="git mergetool --no-prompt"
alias gmtvim="git mergetool --no-prompt --tool=vimdiff"
alias gp="git push"
alias gpd="git push --dry-run"
alias gpf="git push --force-with-lease"
alias "gpf!"="git push --force"
alias gpoat="git push origin --all && git push origin --tags"
alias gpristine="git reset --hard && git clean -dffx"
alias gpu="git push upstream"
alias gpv="git push -v"
alias gr="git remote"
alias gra="git remote add"
alias grb="git rebase"
alias grba="git rebase --abort"
alias grbc="git rebase --continue"
alias grbd="git rebase develop"
alias grbi="git rebase -i"
alias grbs="git rebase --skip"
alias grev="git revert"
alias grh="git reset"
alias grhh="git reset --hard"
alias grm="git rm"
alias grmc="git rm --cached"
alias grmv="git remote rename"
alias grrm="git remote remove"
alias grs="git restore"
alias grset="git remote set-url"
alias grss="git restore --source"
alias gru="git reset --"
alias grup="git remote update"
alias grv="git remote -v"
alias gsb="git status -sb"
alias gsd="git svn dcommit"
alias gsh="git show"
alias gsi="git submodule init"
alias gsps="git show --pretty=short --show-signature"
alias gsr="git svn rebase"
alias gss="git status -s"
alias gst="git status"
alias gsta="git stash push"
alias gstaa="git stash apply"
alias gstall="git stash --all"
alias gstc="git stash clear"
alias gstd="git stash drop"
alias gstl="git stash list"
alias gstp="git stash pop"
alias gsts="git stash show --text"
alias gstu="git stash --include-untracked"
alias gsu="git submodule update"
alias gsw="git switch"
alias gswc="git switch -c"
alias gtl="gtl(){ git tag --sort=-v:refname -n -l "${1}*" }; noglob gtl"
alias gts="git tag -s"
alias gtv="git tag | sort -V"
alias gunignore="git update-index --no-assume-unchanged"
alias gunwip="git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1"
alias gup="git pull --rebase"
alias gupa="git pull --rebase --autostash"
alias gupav="git pull --rebase --autostash -v"
alias gupv="git pull --rebase -v"
alias gwch="git whatchanged -p --abbrev-commit --pretty=medium"
EOF

    echo "✔ ZSH 自定义文件创建完成！"
    echo "------------------------------"

    # 下载并替换 .zshrc
    echo "▶ 正在下载 .zshrc..."
    curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.zshrc -o "$HOME/.zshrc"
    echo "✔ ZSH 配置已安装。"
    echo "------------------------------"

else
    echo "=== 开始安装 BASH 配置 ==="

    # 安装 Oh My Bash
    echo "▶ 正在安装 Oh My Bash..."
    if [ ! -d "$HOME/.oh-my-bash" ]; then
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
        echo "✔ Oh My Bash 安装成功！"
    else
        echo "✔ Oh My Bash 已经安装，跳过安装。"
    fi
    echo "------------------------------"

    # 安装 Bash 需要的工具
    echo "▶ 正在安装 Bash 依赖工具..."
    $SUDO apt-get install -y \
        trash-cli \
        ripgrep \
        fd-find \
        npm

    # 创建 fd 符号链接
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        $SUDO ln -s $(which fdfind) /usr/local/bin/fd
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
    echo "------------------------------"

    # 下载并替换自定义点文件
    echo "▶ 正在下载 .bashrc .bash_aliases..."
    curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.bashrc -o "$HOME/.bashrc"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.bash_aliases -o "$HOME/.bash_aliases"
    echo "✔ Bash 配置已安装。"
    echo "------------------------------"
fi

# --- 下载其他配置文件 ---
echo "▶ 正在配置其他配置文件..."

# Git 配置
read -t 10 -p "是否安装 Git 配置 (.gitconfig)? (y/N) " INSTALL_GIT || INSTALL_GIT="N"
if [[ "$INSTALL_GIT" =~ ^[Yy]$ ]]; then
    echo "▶ 正在下载 .gitconfig..."
    curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.gitconfig -o "$HOME/.gitconfig"
    echo "✔ Git 配置已安装。"
else
    echo "⏭ 跳过 Git 配置。"
fi

# Alacritty 配置
read -t 10 -p "是否安装 Alacritty 配置 (github_dark_dimmed.toml, alacritty.toml)? (y/N) " INSTALL_ALACRITTY || INSTALL_ALACRITTY="N"
if [[ "$INSTALL_ALACRITTY" =~ ^[Yy]$ ]]; then
    echo "▶ 正在下载 Alacritty 配置..."
    mkdir -p "$HOME/.config/alacritty/themes/themes"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.config/alacritty/themes/themes/github_dark_dimmed.toml -o "$HOME/.config/alacritty/themes/themes/github_dark_dimmed.toml"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.config/alacritty/alacritty.toml -o "$HOME/.config/alacritty/alacritty.toml"
    echo "✔ Alacritty 配置已安装。"
else
    echo "⏭ 跳过 Alacritty 配置。"
fi

# Kitty 配置
read -t 10 -p "是否安装 Kitty 配置 (current-theme.conf, kitty.conf)? (y/N) " INSTALL_KITTY || INSTALL_KITTY="N"
if [[ "$INSTALL_KITTY" =~ ^[Yy]$ ]]; then
    echo "▶ 正在下载 Kitty 配置..."
    mkdir -p "$HOME/.config/kitty"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.config/kitty/current-theme.conf -o "$HOME/.config/kitty/current-theme.conf"
    curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.config/kitty/kitty.conf -o "$HOME/.config/kitty/kitty.conf"
    echo "✔ Kitty 配置已安装。"
else
    echo "⏭ 跳过 Kitty 配置。"
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
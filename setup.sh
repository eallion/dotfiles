#!/bin/bash
#
# 自适应 Shell 环境配置脚本，支持 bash 和 fish
# 自动检测执行脚本的 shell 并安装相应配置
#
set -e

TEMP_FILES=()
cleanup_temp() {
    for f in "${TEMP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null
    done
}
trap cleanup_temp EXIT

# 包名 -> 命令名映射
declare -A PKG_CMD_MAP=(
    [trash-cli]="trash"
    [ripgrep]="rg"
    [fd-find]="fd"
    [bat]="batcat"
)

is_installed() {
    local pkg="$1"
    local cmd="${PKG_CMD_MAP[$pkg]:-$pkg}"

    command -v "$cmd" &>/dev/null || dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
}

###
# 回滚功能
###
if [[ "$1" == "--rollback" || "$1" == "-r" ]]; then
    BACKUP_DIR="$HOME/.config/dotfiles"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "❌ 未找到备份目录: $BACKUP_DIR"
        echo "没有可回滚的配置。"
        exit 1
    fi

    echo "=== 配置回滚 ==="
    echo "可用备份:"
    ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r | head -10
    echo ""

    LATEST_BACKUP=$(ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r | head -1)
    if [[ -z "$LATEST_BACKUP" ]]; then
        echo "❌ 未找到任何备份。"
        exit 1
    fi

    printf "使用最新备份 '%s' 进行回滚? (y/N) " "$LATEST_BACKUP"
    if read -t 10 CONFIRM_ROLLBACK < /dev/tty; then :; else CONFIRM_ROLLBACK="N"; echo ""; fi

    if [[ "$CONFIRM_ROLLBACK" =~ ^[Yy]$ ]]; then
        BACKUP_PATH="$BACKUP_DIR/$LATEST_BACKUP"
        echo "▶ 正在回滚配置..."

        find "$BACKUP_PATH" -type f | while read -r file; do
            rel_path="${file#$BACKUP_PATH/}"
            dest="$HOME/$rel_path"
            mkdir -p "$(dirname "$dest")"
            cp -f "$file" "$dest"
            echo "✔ 已恢复 ~/$rel_path"
        done

        echo ""
        echo "✅ 回滚完成！请重启终端或运行 source 命令应用更改。"
    else
        echo "⏭ 回滚已取消。"
    fi
    exit 0
fi

if [[ "$1" == "--clean-backup" || "$1" == "-c" ]]; then
    BACKUP_DIR="$HOME/.config/dotfiles"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "❌ 未找到备份目录: $BACKUP_DIR"
        echo "没有需要清除的备份。"
        exit 0
    fi

    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    if [[ "$BACKUP_COUNT" -eq 0 ]]; then
        echo "❌ 备份目录为空，没有需要清除的备份。"
        exit 0
    fi

    echo "=== 清除备份 ==="
    echo "备份目录: $BACKUP_DIR"
    echo "备份数量: $BACKUP_COUNT"
    echo ""
    ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r | head -10
    echo ""

    printf "确定要清除所有备份吗? (y/N) "
    if read -t 10 CONFIRM_CLEAN < /dev/tty; then :; else CONFIRM_CLEAN="N"; echo ""; fi

    if [[ "$CONFIRM_CLEAN" =~ ^[Yy]$ ]]; then
        rm -rf "$BACKUP_DIR"
        echo "✔ 所有备份已清除。"
    else
        echo "⏭ 清除已取消。"
    fi
    exit 0
fi

###
# 检测安装模式：本地或在线
###
# 本地模式：通过 ./install.sh 调用时，第二个参数为 "local"
# 在线模式：通过 curl 管道调用时，第二个参数为空或不传递
INSTALL_MODE_PARAM="${2:-}"

if [[ "$INSTALL_MODE_PARAM" == "local" ]]; then
    INSTALL_MODE="local"
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    DOTFILES_DIR="$SCRIPT_DIR"
else
    INSTALL_MODE="online"
    DOTFILES_DIR=""
fi

###
# 安装模式：minimal, full, server, desktop
###
INSTALL_PROFILE="${3:-}"

case "$INSTALL_PROFILE" in
    --minimal|minimal)
        PROFILE="minimal"
        ;;
    --full|full)
        PROFILE="full"
        ;;
    --server|server)
        PROFILE="server"
        ;;
    --desktop|desktop)
        PROFILE="desktop"
        ;;
    *)
        PROFILE="interactive"
        ;;
esac

###
# 辅助函数：获取配置文件
###
get_config_file() {
    local file_path="$1"
    local dest_file="$2"
    mkdir -p "$(dirname "$dest_file")"
    
    if [[ "$INSTALL_MODE" == "local" ]]; then
        # 本地模式：从本地仓库复制
        if [[ -f "$DOTFILES_DIR/$file_path" ]]; then
            cp "$DOTFILES_DIR/$file_path" "$dest_file"
            return 0
        else
            echo "⚠ 本地文件未找到: $file_path"
            return 1
        fi
    else
        # 在线模式：从 GitHub 下载
        curl -sSL "https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/$file_path" -o "$dest_file"
        return $?
    fi
}

###
# 辅助函数：命令行多选工具
###
select_tools() {
    local title="$1"
    shift
    local options=("$@")
    
    local selected=()
    local i
    local all_idx=-1
    local skip_idx=-1
    for ((i=0; i<${#options[@]}; i++)); do
        selected[i]=0
        if [[ "${options[i]}" == "ALL" ]]; then all_idx=$i; fi
        if [[ "${options[i]}" == "SKIP" ]]; then skip_idx=$i; fi
    done

    # 默认选中 ALL (如果存在)
    if (( all_idx >= 0 )); then
        selected[all_idx]=1
    fi

    local current=0
    local key=""
    
    echo "------------------------------" >&2
    echo "▶ $title (↑/↓移动，空格选择/取消，回车确认):" >&2
    
    # 隐藏光标
    tput civis >&2 || true

    # 打印空行撑开菜单区域，防止回退覆盖其他内容
    for ((i=0; i<${#options[@]}; i++)); do
        echo "" >&2
    done
    # 光标回到菜单顶部
    echo -en "\033[${#options[@]}A" >&2

    while true; do
        for ((i=0; i<${#options[@]}; i++)); do
            local prefix="   "
            if [[ $i == $current ]]; then
                prefix=" > "
            fi
            
            local check="[ ]"
            if [[ ${selected[i]} == 1 ]]; then
                check="[*]"
            fi
            
            if [[ $i == $current ]]; then
                # \r 归位首列，\033[K 清除到行尾
                echo -e "\r\033[1;32m$prefix$check ${options[i]}\033[0m\033[K" >&2
            else
                echo -e "\r$prefix$check ${options[i]}\033[K" >&2
            fi
        done
        
        # 光标移回菜单顶部进行下一次重绘
        echo -en "\033[${#options[@]}A\r" >&2
        
        IFS= read -rsn1 key < /dev/tty
        if [[ $key == $'\x1b' ]]; then
            # 读取转义序列
            read -rsn2 key < /dev/tty
            if [[ $key == "[A" || $key == "OA" || $key == "A" ]]; then # 上
                ((current--))
                if ((current < 0)); then current=$((${#options[@]} - 1)); fi
            elif [[ $key == "[B" || $key == "OB" || $key == "B" ]]; then # 下
                ((current++))
                if ((current >= ${#options[@]})); then current=0; fi
            fi
        elif [[ $key == " " ]]; then # 空格
            if [[ ${selected[current]} == 1 ]]; then
                selected[current]=0
            else
                selected[current]=1
                # 互斥处理
                if [[ $current == $all_idx ]]; then
                    for ((i=0; i<${#options[@]}; i++)); do
                        if [[ $i != $all_idx ]]; then selected[i]=0; fi
                    done
                elif [[ $current == $skip_idx ]]; then
                    for ((i=0; i<${#options[@]}; i++)); do
                        if [[ $i != $skip_idx ]]; then selected[i]=0; fi
                    done
                else
                    if (( all_idx >= 0 )); then selected[all_idx]=0; fi
                    if (( skip_idx >= 0 )); then selected[skip_idx]=0; fi
                fi
            fi
        elif [[ "$key" == "" ]]; then # Enter
            break
        fi
    done

    # 循环结束，光标移动到选项下方恢复正常输出
    echo -en "\033[${#options[@]}B\r" >&2
    tput cnorm >&2 || true
    
    local results=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${selected[i]} == 1 ]]; then
            results+=("${options[i]}")
        fi
    done
    
    if [[ ${#results[@]} -eq 0 ]]; then
        if (( skip_idx >= 0 )); then
            echo "SKIP"
        else
            echo "ALL"
        fi
    else
        echo "${results[*]}"
    fi
}

###
# 辅助函数：安装 CLI 工具
###
install_cli_tools() {
    local title="$1"
    shift
    local tools=("$@")
    
    local selected_cli
    case "$PROFILE" in
        minimal)
            echo "⏭ 最小模式，跳过 CLI 工具安装。"
            return 0
            ;;
        full|desktop)
            selected_cli="ALL"
            ;;
        server)
            selected_cli="ALL"
            ;;
        *)
            selected_cli=$(select_tools "$title" "${tools[@]}")
            ;;
    esac
    
    if [[ "$selected_cli" == *"SKIP"* ]] || [[ -z "$selected_cli" ]]; then
        echo "⏭ 跳过现代 CLI 工具安装。"
        return 0
    fi
    
    local tools_to_install=()
    if [[ "$selected_cli" == *"ALL"* ]]; then
        for tool in "${tools[@]}"; do
            if [[ "$tool" != "ALL" && "$tool" != "SKIP" ]]; then
                tools_to_install+=("$tool")
            fi
        done
    else
        for tool in $selected_cli; do
            if [[ "$tool" != "ALL" && "$tool" != "SKIP" ]]; then
                tools_to_install+=("$tool")
            fi
        done
    fi
    
    if [[ ${#tools_to_install[@]} -eq 0 ]]; then
        echo "⏭ 没有选择任何工具，跳过安装。"
        return 0
    fi

    local final_tools=()
    local skipped_tools=()
    for tool in "${tools_to_install[@]}"; do
        if is_installed "$tool"; then
            skipped_tools+=("$tool")
        else
            final_tools+=("$tool")
        fi
    done

    if [[ ${#skipped_tools[@]} -gt 0 ]]; then
        echo "⏭ 已安装，跳过: ${skipped_tools[*]}"
    fi

    if [[ ${#final_tools[@]} -eq 0 ]]; then
        echo "✔ 所有选中的工具均已安装。"
        return 0
    fi

    echo "▶ 正在安装选中的 CLI 工具: ${final_tools[*]}"
    $SUDO apt-get install -y "${final_tools[@]}" || echo "⚠ 部分工具安装失败，脚本将继续。"
    
    if [[ " ${final_tools[*]} " =~ " bat " ]] && command -v batcat &> /dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        echo "✔ 已创建 ~/.local/bin/bat -> $(command -v batcat)"
    fi
    
    if [[ " ${final_tools[*]} " =~ " fd-find " ]] && command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        $SUDO ln -sf "$(command -v fdfind)" /usr/local/bin/fd
    fi
}

###
# 辅助函数：安装 Fisher 及插件
###
install_fisher_plugins() {
    if ! command -v fish &> /dev/null; then
        echo "⚠ 未安装 fish，跳过 fisher 插件安装。"
        return 0
    fi

    if fish -c "type -q fisher" 2>/dev/null; then
        echo "✔ Fisher 已安装，跳过安装。"
    else
        echo "▶ 正在安装 Fisher 插件管理器..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null
        echo "✔ Fisher 安装完成"
    fi

    local fish_plugins_file="$HOME/.config/fish/fish_plugins"
    if [[ ! -f "$fish_plugins_file" ]]; then
        get_config_file ".config/fish/fish_plugins" "$fish_plugins_file" 2>/dev/null || true
    fi
    if [[ ! -f "$fish_plugins_file" ]]; then
        echo "⚠ 未找到 fish_plugins 文件，跳过插件安装。"
        return 0
    fi

    local plugins=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        plugins+=("$line")
    done < "$fish_plugins_file"

    if [[ ${#plugins[@]} -eq 0 ]]; then
        echo "⏭ 没有需要安装的插件。"
        return 0
    fi

    local installed_plugins
    installed_plugins=$(fish -c "fisher list" 2>/dev/null)

    local plugins_to_install=()
    local skipped_plugins=()
    for plugin in "${plugins[@]}"; do
        local plugin_lower
        plugin_lower=$(echo "$plugin" | tr '[:upper:]' '[:lower:]')
        if echo "$installed_plugins" | tr '[:upper:]' '[:lower:]' | grep -q "^${plugin_lower}$"; then
            skipped_plugins+=("$plugin")
        else
            plugins_to_install+=("$plugin")
        fi
    done

    if [[ ${#skipped_plugins[@]} -gt 0 ]]; then
        echo "⏭ 已安装，跳过: ${skipped_plugins[*]}"
    fi

    if [[ ${#plugins_to_install[@]} -gt 0 ]]; then
        echo "▶ 正在安装 fisher 插件: ${plugins_to_install[*]}"
        fish -c "fisher install ${plugins_to_install[*]}" 2>/dev/null
        echo "✔ fisher 插件安装完成"
    else
        echo "✔ 所有 fisher 插件均已安装。"
    fi
}

###
# 系统与虚拟化/容器环境检测
###
VIRT_TYPE="none"
IS_PVE_LXC=false
ENV_DESC="物理机 (Bare Metal)"
DISTRO_ID="unknown"
DISTRO_NAME="Linux"
DISTRO_VERSION="unknown"
DISTRO_MAJOR=0
IS_MODERN_SYSTEM=false

detect_system_info() {
    # 1. 检测虚拟化 / 容器环境
    if command -v systemd-detect-virt &> /dev/null; then
        VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo "none")
    fi

    if [[ "$VIRT_TYPE" == "lxc" ]] || [[ -f /run/systemd/container && $(cat /run/systemd/container 2>/dev/null) == "lxc" ]] || grep -qa 'container=lxc' /proc/1/environ 2>/dev/null; then
        VIRT_TYPE="lxc"
        # 进一步检测是否为 Proxmox VE (PVE) LXC:
        # PVE 宿主机内核在 uname -r 或 /proc/version 中包含 -pve
        if uname -r | grep -qi "pve" || grep -qi "pve" /proc/version 2>/dev/null; then
            IS_PVE_LXC=true
            ENV_DESC="Proxmox VE (PVE) LXC 容器"
        else
            ENV_DESC="LXC 容器"
        fi
    elif [[ "$VIRT_TYPE" == "docker" ]] || [ -f /.dockerenv ]; then
        ENV_DESC="Docker 容器"
    elif grep -qi "microsoft" /proc/version 2>/dev/null; then
        VIRT_TYPE="wsl"
        ENV_DESC="Windows WSL 环境"
    elif [[ "$VIRT_TYPE" != "none" ]]; then
        ENV_DESC="虚拟机 ($VIRT_TYPE)"
    fi

    # 2. 检测发行版与版本
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_NAME="${NAME:-Linux}"
        DISTRO_VERSION="${VERSION_ID:-0}"
    elif command -v lsb_release &> /dev/null; then
        DISTRO_ID=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        DISTRO_NAME=$(lsb_release -ds)
        DISTRO_VERSION=$(lsb_release -sr)
    fi

    DISTRO_MAJOR=$(echo "$DISTRO_VERSION" | sed -E 's/^([0-9]+).*/\1/')
    if ! [[ "$DISTRO_MAJOR" =~ ^[0-9]+$ ]]; then
        DISTRO_MAJOR=0
    fi

    # 检查是否为 Debian / Ubuntu 体系
    IS_DEBIAN_LIKE=false
    if [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "${ID_LIKE:-}" =~ (debian|ubuntu) ]] || [ -f /etc/debian_version ]; then
        IS_DEBIAN_LIKE=true
    fi

    # 现代化系统判定：Ubuntu >= 22.04（包括 24.04, 26.04+），Debian >= 12（包括 13+）
    if [[ "$DISTRO_ID" == "ubuntu" && "$DISTRO_MAJOR" -ge 22 ]] || \
       [[ "$DISTRO_ID" == "debian" && "$DISTRO_MAJOR" -ge 12 ]]; then
        IS_MODERN_SYSTEM=true
    fi
}
detect_system_info

if [[ "$IS_DEBIAN_LIKE" == false ]]; then
    echo "⚠ 警告: 本脚本专为 Debian / Ubuntu (Deb 系) 系统设计，当前系统可能无法保证兼容性。"
fi

###
# 第一步：用户检查与处理（Root 用户处理）
###
if [[ "$EUID" -eq 0 ]]; then
    echo "▶ 检测到当前为 root 用户。"
    echo "为了安全性，建议创建/使用一个普通用户来运行此脚本。"
    printf "是否创建/切换到普通用户? (y/N) "
    if read -t 10 CREATE_USER < /dev/tty; then :; else CREATE_USER="N"; echo ""; fi

    if [[ "$CREATE_USER" =~ ^[Yy]$ ]]; then
        printf "请输入用户名: "
        read -t 30 USERNAME < /dev/tty
        if [[ -z "$USERNAME" ]]; then
            echo "❌ 用户名不能为空"
            exit 1
        fi

        # 检查用户是否存在
        if id "$USERNAME" &>/dev/null 2>&1; then
            echo "✔ 用户 $USERNAME 已存在，将切换到该用户"
        else
            echo "▶ 用户 $USERNAME 不存在，正在创建..."
            useradd -m -s /bin/bash "$USERNAME"
            echo "✔ 用户 $USERNAME 创建成功"
        fi

        # 在切换前以 root 身份直接写入 sudoers，新用户无需输入任何密码
        echo "▶ 正在为 $USERNAME 配置 sudo 免密权限..."
        mkdir -p /etc/sudoers.d
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-"$USERNAME"
        chmod 440 /etc/sudoers.d/90-"$USERNAME"
        echo "✔ sudo 免密权限配置完成"

        # 切换到该用户并重新运行脚本
        # 兼容 curl 管道模式：$0 可能是 "bash"，此时用 /proc/self/fd/0 读取
        echo "▶ 切换到用户 $USERNAME 并重新运行脚本..."
        SCRIPT_PATH="${BASH_SOURCE[0]}"
        if [[ -f "$SCRIPT_PATH" ]]; then
            su - "$USERNAME" -c "bash '$SCRIPT_PATH' $*"
        else
            echo "⚠ 在线安装模式：请切换到 $USERNAME 后重新运行安装命令。"
            echo "  su - $USERNAME"
        fi
        exit 0
    fi
    # 如果不创建新用户，作为 root 继续
    SUDO=""
fi

# 优先检查显式传递的参数
if [[ -n "$1" ]]; then
    if [[ "$1" == "bash" ]]; then
        INSTALL_SHELL="bash"
    elif [[ "$1" == "zsh" ]]; then
        INSTALL_SHELL="zsh"
    elif [[ "$1" == "fish" ]]; then
        INSTALL_SHELL="fish"
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

    if [[ "$DETECTED_SHELL" == "fish" ]]; then
        INSTALL_SHELL="fish"
    elif [[ "$DETECTED_SHELL" == "zsh" ]]; then
        INSTALL_SHELL="zsh"
    elif [[ "$DETECTED_SHELL" == "bash" || "$DETECTED_SHELL" == "sh" ]]; then
        if [[ "$0" == "fish" ]]; then
            INSTALL_SHELL="fish"
        elif [[ "$0" == "zsh" ]]; then
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
echo "▶ 操作系统: $DISTRO_NAME $DISTRO_VERSION"
echo "▶ 运行环境: $ENV_DESC"
echo "脚本将自动备份你的配置文件"
echo "------------------------------"

cd ~

echo "------------------------------"

###
# 第二步：普通用户处理（如果不是 root）
###
if [[ "$EUID" -ne 0 ]]; then
    echo "▶ 检测到当前为普通用户。安装命令将使用 sudo 运行。"
    SUDO="sudo"

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
    CURRENT_USER=$(whoami)
    if ! $SUDO -n true 2>/dev/null; then
        echo "❌ 当前用户 $CURRENT_USER 没有 sudo 权限。"
        echo ""
        printf "是否通过 su 自动配置 sudoers（需要输入 root 密码）? (y/N) "
        if read -t 15 AUTO_SUDO < /dev/tty; then :; else AUTO_SUDO="N"; echo ""; fi

        if [[ "$AUTO_SUDO" =~ ^[Yy]$ ]]; then
            echo "▶ 请输入 root 密码（以下操作以 root 身份执行）："
            SUDOERS_CMD="mkdir -p /etc/sudoers.d && echo '$CURRENT_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-$CURRENT_USER && chmod 440 /etc/sudoers.d/90-$CURRENT_USER"
            if su root -c "$SUDOERS_CMD" < /dev/tty; then
                echo "✔ sudoers 配置成功！"
                # sudoers 文件写入后无需重登录，立即验证
                if ! $SUDO -n true 2>/dev/null; then
                    echo "⚠ 配置已写入，但当前会话尚未生效，请重新登录后再运行本脚本。"
                    exit 0
                fi
                echo "✔ sudo 权限验证通过，继续执行..."
            else
                echo "❌ 自动配置失败（root 密码错误或 su 不可用）。"
                echo ""
                echo "请手动以 root 身份执行以下命令后，重新运行本脚本："
                echo "  echo '$CURRENT_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-$CURRENT_USER"
                exit 1
            fi
        else
            echo ""
            echo "请手动以 root 身份执行以下任一命令后，重新运行本脚本："
            echo "  方法一: usermod -aG sudo $CURRENT_USER"
            echo "  方法二: echo '$CURRENT_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-$CURRENT_USER"
            echo ""
            echo "或者直接以 root 运行本脚本，脚本会引导你创建/切换用户。"
            exit 1
        fi
    fi

    echo "⚠️  安全警告: 即将配置 sudo 免密码 (NOPASSWD)！"
    echo "   此配置允许当前用户无需密码执行任何 root 命令。"
    echo "   如果这是共享电脑或服务器，可能存在安全风险。"
    echo "   如需修改，可编辑: /etc/sudoers.d/90-$CURRENT_USER"
    echo "▶ 正在配置 sudo 免密码..."
    # 尝试配置免密
    if echo "$CURRENT_USER ALL=(ALL) NOPASSWD:ALL" | $SUDO tee /etc/sudoers.d/90-$CURRENT_USER > /dev/null 2>&1; then
        $SUDO chmod 440 /etc/sudoers.d/90-$CURRENT_USER
        if command -v visudo &>/dev/null && ! $SUDO visudo -c -f /etc/sudoers.d/90-$CURRENT_USER > /dev/null 2>&1; then
            echo "⚠ sudoers 语法校验失败，已自动回滚以避免 sudo 损坏。"
            $SUDO rm -f /etc/sudoers.d/90-$CURRENT_USER
        else
            echo "✔ sudo 免密码配置成功！"
        fi
    else
        echo "⚠ sudo 免密码配置失败，脚本将继续运行，后续可能需要手动输入密码。"
    fi
else
    SUDO=""
    echo "▶ 当前为 root 用户，所有安装命令将直接运行。"
fi
echo "------------------------------"

# --- 备份文件 ---
BACKUP_DIR="$HOME/.config/dotfiles"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

case "$PROFILE" in
    minimal) BACKUP_FILES="N" ;;
    full|desktop|server) BACKUP_FILES="Y" ;;
    *)
        printf "是否备份现有的配置文件? (y/N) "
        if read -t 10 BACKUP_FILES < /dev/tty; then :; else BACKUP_FILES="N"; echo ""; fi
        ;;
esac

if [[ "$BACKUP_FILES" =~ ^[Yy]$ ]]; then
    mkdir -p "$BACKUP_PATH"
    backup_files=()

    if [[ "$INSTALL_SHELL" == "bash" ]]; then
        backup_files+=(".bashrc" ".aliases")
    elif [[ "$INSTALL_SHELL" == "zsh" ]]; then
        backup_files+=(".zshrc" ".aliases")
    elif [[ "$INSTALL_SHELL" == "fish" ]]; then
        backup_files+=(".config/fish/config.fish" ".config/fish/functions/aliases.fish" ".config/fish/fish_plugins")
    fi

    # 包含可能被脚本覆盖的通用配置文件
    for common_cfg in ".gitconfig" ".login_info.sh" ".config/starship.toml" ".config/starship-plain.toml" ".config/kitty/current-theme.conf" ".config/kitty/kitty.conf" ".config/ghostty/config.ghostty" ".config/ghostty/auto/theme.ghostty"; do
        if [ -f "$HOME/$common_cfg" ]; then
            backup_files+=("$common_cfg")
        fi
    done

    for file in "${backup_files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            dest_dir="$BACKUP_PATH/$(dirname "$file")"
            mkdir -p "$dest_dir"
            cp "$HOME/$file" "$BACKUP_PATH/$file"
            echo "✔ 备份 ~/$file"
        fi
    done
    echo "✔ 备份已保存至: $BACKUP_PATH"
else
    echo "⏭ 跳过备份。"
fi
echo "------------------------------"

###
# 第三步：检查目标 Shell 安装状态
###
echo "▶ 检查目标 Shell 安装状态..."
if [[ "$INSTALL_SHELL" == "fish" ]]; then
    echo "▶ 检查 Fish 安装状态..."
    if ! command -v fish &> /dev/null; then
        echo "❌ 未检测到 fish，这是目标 shell 所需的。"
        echo "请先手动安装 fish 后再运行此脚本。"
        exit 1
    else
        echo "✔ fish 已安装。"
    fi
elif [[ "$INSTALL_SHELL" == "zsh" ]]; then
    echo "▶ 检查 ZSH 安装状态..."
    if ! command -v zsh &> /dev/null; then
        echo "❌ 未检测到 zsh，这是目标 shell 所需的。"
        echo "请先手动安装 zsh 后再运行此脚本。"
        exit 1
    else
        echo "✔ zsh 已安装。"
    fi
else
    echo "▶ 目标 shell 为 bash，跳过 shell 安装检查。"
fi
echo "------------------------------"

# --- 更新包管理器与安装基础工具 ---
install_basic_tools() {
    local tools=("$@")
    local final_tools=()
    local skipped_tools=()

    for tool in "${tools[@]}"; do
        if is_installed "$tool"; then
            skipped_tools+=("$tool")
        else
            final_tools+=("$tool")
        fi
    done

    if [[ ${#skipped_tools[@]} -gt 0 ]]; then
        echo "⏭ 已安装，跳过: ${skipped_tools[*]}"
    fi

    if [[ ${#final_tools[@]} -gt 0 ]]; then
        echo "▶ 正在更新包管理器..."
        $SUDO apt-get update
        echo "✔ 包管理器更新完成"
        echo "▶ 正在安装基础工具: ${final_tools[*]}"
        $SUDO apt-get install -y "${final_tools[@]}"
        echo "✔ 基础工具安装完成"
    else
        echo "✔ 所有基础工具均已安装。"
    fi
}

case "$PROFILE" in
    minimal)
        echo "⏭ 最小模式，跳过基础工具安装。"
        ;;
    full|desktop)
        echo "▶ 安装基础工具 (full 模式)..."
        install_basic_tools curl wget git ca-certificates jq neovim ncurses-term
        ;;
    server)
        echo "▶ 安装服务器基础工具..."
        install_basic_tools curl wget git ca-certificates ncurses-term
        ;;
    *)
        echo "▶ 选择要安装的基础工具："
        basic_tools=("ALL" "curl" "wget" "git" "ca-certificates" "jq" "neovim" "ncurses-term" "SKIP")
        selected_basic=$(select_tools "基础工具安装" "${basic_tools[@]}")

        if [[ "$selected_basic" == *"SKIP"* ]] || [[ -z "$selected_basic" ]]; then
            echo "⏭ 跳过基础工具安装。"
        else
            tools_to_install=()
            if [[ "$selected_basic" == *"ALL"* ]]; then
                tools_to_install=("curl" "wget" "git" "ca-certificates" "jq" "neovim" "ncurses-term")
            else
                for tool in $selected_basic; do
                    if [[ "$tool" != "ALL" && "$tool" != "SKIP" ]]; then
                        tools_to_install+=("$tool")
                    fi
                done
            fi

            if [[ ${#tools_to_install[@]} -gt 0 ]]; then
                install_basic_tools "${tools_to_install[@]}"
            else
                echo "⏭ 没有选择任何工具，跳过安装。"
            fi
        fi
        ;;
esac
echo "------------------------------"

# --- 安装 Starship ---
echo "=== Starship 提示符配置 ==="
STARSHIP_ALREADY_INSTALLED=false
if command -v starship &> /dev/null; then
    STARSHIP_ALREADY_INSTALLED=true
    echo "✔ 检测到 Starship 已安装: $(starship --version 2>/dev/null | head -n1)"
fi

INSTALL_STARSHIP="N"
case "$PROFILE" in
    minimal)
        INSTALL_STARSHIP="N"
        ;;
    full|desktop|server)
        INSTALL_STARSHIP="Y"
        ;;
    *)
        if [[ "$STARSHIP_ALREADY_INSTALLED" == true ]]; then
            printf "是否重新安装/更新 Starship? (y/N) "
            if read -t 10 REINSTALL_STARSHIP < /dev/tty; then :; else REINSTALL_STARSHIP="N"; echo ""; fi
            if [[ "$REINSTALL_STARSHIP" =~ ^[Yy]$ ]]; then
                INSTALL_STARSHIP="Y"
            fi
        else
            printf "是否安装 Starship 提示符? (y/N) "
            if read -t 15 INSTALL_STARSHIP < /dev/tty; then :; else INSTALL_STARSHIP="N"; echo ""; fi
        fi
        ;;
esac

if [[ "$INSTALL_STARSHIP" =~ ^[Yy]$ ]]; then
    echo "▶ 正在安装 Starship..."
    if bash -lc "curl -sS https://starship.rs/install.sh | sh -s -- --yes"; then
        echo "✔ Starship 安装成功！"
    else
        echo "⚠ Starship 安装脚本执行异常，将继续尝试后续配置。"
    fi
    echo "------------------------------"
fi

# 检查当前是否可以使用 starship 命令配置主题
if command -v starship &> /dev/null; then
    CONFIGURE_PRESET="N"
    case "$PROFILE" in
        minimal)
            CONFIGURE_PRESET="N"
            ;;
        full|desktop|server)
            CONFIGURE_PRESET="Y"
            ;;
        *)
            printf "是否配置 Starship 官方 Preset 主题? (Y/n) "
            if read -t 15 CONFIGURE_PRESET < /dev/tty; then :; else CONFIGURE_PRESET="Y"; echo ""; fi
            [[ -z "$CONFIGURE_PRESET" ]] && CONFIGURE_PRESET="Y"
            ;;
    esac

    if [[ "$CONFIGURE_PRESET" =~ ^[Yy]$ ]]; then
        mkdir -p "$HOME/.config"
        echo "▶ 请选择要安装的 Starship 官方 Preset 主题："
        echo "   1) gruvbox-rainbow      (默认，Gruvbox 彩虹分段，需 Nerd Font)"
        echo "   2) catppuccin-powerline (Catppuccin 莫兰迪配色 Powerline 主题)"
        echo "   3) pastel-powerline     (柔和粉彩配色 Powerline 主题)"
        echo "   4) tokyo-night          (Tokyo Night 配色主题)"
        echo "   5) pure-preset          (仿 Pure 极简风格主题)"
        echo "   6) jetpack              (双行紧凑几何火箭极简主题)"
        echo "   7) bracketed-segments   (方括号包裹各模块分段主题)"
        echo "   8) nerd-font-symbols    (丰富 Nerd Font 图标预设)"
        echo "   9) no-runtime-versions  (隐藏各语言运行时版本号)"
        echo "  10) no-empty-icons       (无环境工具时隐藏图标)"
        echo "  11) plain-text-symbols   (纯文本 ASCII 符号，无 Nerd Font)"
        echo "  12) no-nerd-font         (无 Nerd Font 标准符号预设)"
        echo "  13) 保持现有配置 / 跳过"
        printf "请输入序号 (1-13，默认 1): "
        if read -t 20 PRESET_CHOICE < /dev/tty; then :; else PRESET_CHOICE="1"; echo ""; fi
        [[ -z "$PRESET_CHOICE" ]] && PRESET_CHOICE="1"

        CHOSEN_PRESET=""
        case "$PRESET_CHOICE" in
            1) CHOSEN_PRESET="gruvbox-rainbow" ;;
            2) CHOSEN_PRESET="catppuccin-powerline" ;;
            3) CHOSEN_PRESET="pastel-powerline" ;;
            4) CHOSEN_PRESET="tokyo-night" ;;
            5) CHOSEN_PRESET="pure-preset" ;;
            6) CHOSEN_PRESET="jetpack" ;;
            7) CHOSEN_PRESET="bracketed-segments" ;;
            8) CHOSEN_PRESET="nerd-font-symbols" ;;
            9) CHOSEN_PRESET="no-runtime-versions" ;;
            10) CHOSEN_PRESET="no-empty-icons" ;;
            11) CHOSEN_PRESET="plain-text-symbols" ;;
            12) CHOSEN_PRESET="no-nerd-font" ;;
            13)
                echo "⏭ 保持现有主配置 ~/.config/starship.toml"
                ;;
            *)
                echo "⚠ 无效输入，默认应用 gruvbox-rainbow"
                CHOSEN_PRESET="gruvbox-rainbow"
                ;;
        esac

        if [[ -n "$CHOSEN_PRESET" ]]; then
            echo "▶ 正在应用官方 Preset: $CHOSEN_PRESET -> ~/.config/starship.toml"
            if starship preset "$CHOSEN_PRESET" -o "$HOME/.config/starship.toml" --force 2>/dev/null; then
                echo "✔ 主配置已成功写入: $CHOSEN_PRESET"
            else
                echo "⚠ starship preset 命令执行失败，尝试获取本地仓库/远程模板..."
                get_config_file ".config/starship.toml" "$HOME/.config/starship.toml"
            fi
        fi
        echo "------------------------------"

        # 下一步：是否配置无 Nerd 字体环境时使用的主题
        case "$PROFILE" in
            minimal)
                FALLBACK_PRESET_CHOICE="3"
                ;;
            full|desktop|server)
                FALLBACK_PRESET_CHOICE="1"
                ;;
            *)
                echo "▶ 是否配置无 Nerd 字体环境的兼容主题 (用于 VNC、Web 控制台、TTY 等)？"
                echo "   1) plain-text-symbols (默认，纯文本 ASCII 符号，开箱即用 0 乱码)"
                echo "   2) no-nerd-font       (使用标准 Unicode/Emoji 代替 Nerd Font)"
                echo "   3) 跳过 / 不配置"
                printf "请输入序号 (1-3，默认 1): "
                if read -t 15 FALLBACK_PRESET_CHOICE < /dev/tty; then :; else FALLBACK_PRESET_CHOICE="1"; echo ""; fi
                [[ -z "$FALLBACK_PRESET_CHOICE" ]] && FALLBACK_PRESET_CHOICE="1"
                ;;
        esac

        case "$FALLBACK_PRESET_CHOICE" in
            1)
                echo "▶ 正在生成无 Nerd 字体官方主题: plain-text-symbols -> ~/.config/starship-plain.toml"
                if starship preset plain-text-symbols -o "$HOME/.config/starship-plain.toml" --force; then
                    echo "✔ 已配置无 Nerd 字体兼容主题: plain-text-symbols"
                else
                    echo "⚠ 生成 plain-text-symbols 兼容主题失败。"
                fi
                ;;
            2)
                echo "▶ 正在生成无 Nerd 字体官方主题: no-nerd-font -> ~/.config/starship-plain.toml"
                if starship preset no-nerd-font -o "$HOME/.config/starship-plain.toml" --force; then
                    echo "✔ 已配置无 Nerd 字体兼容主题: no-nerd-font"
                else
                    echo "⚠ 生成 no-nerd-font 兼容主题失败。"
                fi
                ;;
            *)
                echo "⏭ 跳过无 Nerd 字体兼容主题配置。"
                ;;
        esac
    fi
else
    echo "⏭ 未安装 Starship，跳过主题配置。"
fi
echo "------------------------------"

# --- 安装字体 ---
case "$PROFILE" in
    minimal|server) INSTALL_FONTS="N" ;;
    desktop) INSTALL_FONTS="Y" ;;
    *)
        printf "是否安装 JetBrains Maple Mono 字体? (y/N) "
        if read -t 10 INSTALL_FONTS < /dev/tty; then :; else INSTALL_FONTS="N"; echo ""; fi
        ;;
esac

if [[ "$INSTALL_FONTS" =~ ^[Yy]$ ]]; then
    if command -v fc-list &>/dev/null && fc-list 2>/dev/null | grep -qi "JetBrainsMapleMono"; then
        echo "✔ JetBrains Maple Mono 字体已安装，跳过安装。"
    else
        echo "▶ 正在安装 JetBrains Maple Mono 字体..."
        # 确保依赖 unzip 与 fontconfig 存在
        FONT_DEPS=()
        command -v unzip &>/dev/null || FONT_DEPS+=("unzip")
        command -v fc-cache &>/dev/null || FONT_DEPS+=("fontconfig")
        if [[ ${#FONT_DEPS[@]} -gt 0 ]]; then
            $SUDO apt-get install -y "${FONT_DEPS[@]}" 2>/dev/null || true
        fi

        # 字体存放路径：现代系统优先使用 ~/.local/share/fonts，旧系统兼容 ~/.fonts
        if [[ "$IS_MODERN_SYSTEM" == true ]] || [ -d "$HOME/.local/share" ]; then
            FONT_DIR="$HOME/.local/share/fonts"
        else
            FONT_DIR="$HOME/.fonts"
        fi
        mkdir -p "$FONT_DIR"

        FONT_TEMP=$(mktemp -d)
        TEMP_FILES+=("$FONT_TEMP")
        FONT_URL="https://github.com/SpaceTimee/Fusion-JetBrainsMapleMono/releases/latest/download/JetBrainsMapleMono-NF-XX-XX-XX.zip"

        if curl -fsSL "$FONT_URL" -o "$FONT_TEMP/font.zip" || wget -q "$FONT_URL" -O "$FONT_TEMP/font.zip"; then
            unzip -qo "$FONT_TEMP/font.zip" -d "$FONT_TEMP/unzipped" 2>/dev/null || true
            find "$FONT_TEMP/unzipped" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp -f {} "$FONT_DIR/" \; 2>/dev/null || true
            rm -rf "$FONT_TEMP"
            if command -v fc-cache &> /dev/null; then
                fc-cache -f "$FONT_DIR" 2>/dev/null || fc-cache -f -v 2>/dev/null || true
            fi
            echo "✔ JetBrains Maple Mono 字体安装成功！(路径: $FONT_DIR)"
        else
            echo "⚠ 下载字体失败，跳过字体安装。"
            rm -rf "$FONT_TEMP"
        fi
    fi
else
    echo "⏭ 跳过字体安装。"
fi
echo "------------------------------"

# 根据 shell 类型执行相应安装
if [[ "$INSTALL_SHELL" == "fish" ]]; then
    echo "=== 开始安装 FISH 配置 ==="

    # --- [可选] 安装 Fish 现代 CLI 工具 ---
    echo "▶ 选择要安装的现代 CLI 工具："
    install_cli_tools "现代 CLI 工具安装 (Fish)" "ALL" "trash-cli" "ripgrep" "fd-find" "eza" "bat" "fzf" "zoxide" "gh" "btop" "SKIP"
    echo "------------------------------"

    # --- 安装 Fish 配置文件 ---
    case "$PROFILE" in
        minimal) INSTALL_FISH_CONFIG="N" ;;
        full|desktop) INSTALL_FISH_CONFIG="Y" ;;
        *)
            printf "是否安装 Fish 配置文件 (.config/fish/config.fish, .config/fish/functions/aliases.fish, .login_info.sh)? (y/N) "
            if read -t 10 INSTALL_FISH_CONFIG < /dev/tty; then :; else INSTALL_FISH_CONFIG="N"; echo ""; fi
            ;;
    esac

    if [[ "$INSTALL_FISH_CONFIG" =~ ^[Yy]$ ]]; then
        mkdir -p "$HOME/.config/fish/functions"
        echo "▶ 正在下载 fish 配置..."
        get_config_file ".config/fish/config.fish" "$HOME/.config/fish/config.fish"
        get_config_file ".config/fish/functions/aliases.fish" "$HOME/.config/fish/functions/aliases.fish"
        get_config_file ".config/fish/fish_plugins" "$HOME/.config/fish/fish_plugins"
        get_config_file ".login_info.sh" "$HOME/.login_info.sh"

        if command -v nvim &> /dev/null; then
            if ! grep -q 'abbr --add vim nvim' "$HOME/.config/fish/functions/aliases.fish" 2>/dev/null; then
                echo '' >> "$HOME/.config/fish/functions/aliases.fish"
                echo 'if type -q nvim' >> "$HOME/.config/fish/functions/aliases.fish"
                echo '    abbr --add vim nvim' >> "$HOME/.config/fish/functions/aliases.fish"
                echo 'end' >> "$HOME/.config/fish/functions/aliases.fish"
            fi
            echo "✔ 已添加 vim -> nvim 的 fish 缩写"
        fi

        if ! grep -q 'functions/aliases.fish' "$HOME/.config/fish/config.fish" 2>/dev/null; then
            echo '' >> "$HOME/.config/fish/config.fish"
            echo '    if test -f $HOME/.config/fish/functions/aliases.fish' >> "$HOME/.config/fish/config.fish"
            echo '        source $HOME/.config/fish/functions/aliases.fish' >> "$HOME/.config/fish/config.fish"
            echo '    end' >> "$HOME/.config/fish/config.fish"
            echo "✔ 已补充 fish 启动时加载 aliases.fish"
        fi

        echo "✔ Fish 配置已安装。"
    else
        echo "⏭ 跳过 Fish 配置文件安装。"
    fi
    echo "------------------------------"

    # --- 安装 Fisher 及插件 ---
    case "$PROFILE" in
        minimal) INSTALL_FISHER="N" ;;
        full|desktop) INSTALL_FISHER="Y" ;;
        *)
            printf "是否安装 Fisher 及常见插件 (fycu, autopair, puffer, done, fzf.fish, zoxide.fish, colored-man)? (y/N) "
            if read -t 10 INSTALL_FISHER < /dev/tty; then :; else INSTALL_FISHER="N"; echo ""; fi
            ;;
    esac

    if [[ "$INSTALL_FISHER" =~ ^[Yy]$ ]]; then
        install_fisher_plugins
    else
        echo "⏭ 跳过 Fisher 插件安装。"
    fi
    echo "------------------------------"

elif [[ "$INSTALL_SHELL" == "zsh" ]]; then
    echo "=== 开始安装 ZSH 配置 ==="

    # --- [可选] 安装 Zsh 现代 CLI 工具 ---
    echo "▶ 选择要安装的现代 CLI 工具："
    install_cli_tools "现代 CLI 工具安装 (Zsh)" "ALL" "trash-cli" "ripgrep" "fd-find" "eza" "bat" "fzf" "zoxide" "gh" "btop" "SKIP"
    echo "------------------------------"

    # --- 安装 ZSH 配置文件 ---
    case "$PROFILE" in
        minimal) INSTALL_ZSH_CONFIG="N" ;;
        full|desktop|server) INSTALL_ZSH_CONFIG="Y" ;;
        *)
            printf "是否安装 ZSH 配置文件 (.zshrc, .aliases, .login_info.sh)? (y/N) "
            if read -t 10 INSTALL_ZSH_CONFIG < /dev/tty; then :; else INSTALL_ZSH_CONFIG="N"; echo ""; fi
            ;;
    esac

    if [[ "$INSTALL_ZSH_CONFIG" =~ ^[Yy]$ ]]; then
        echo "▶ 正在下载 .zshrc .aliases .login_info.sh..."
        get_config_file ".zshrc" "$HOME/.zshrc"
        get_config_file ".aliases" "$HOME/.aliases"
        get_config_file ".login_info.sh" "$HOME/.login_info.sh"

        if command -v nvim &> /dev/null; then
            if ! grep -q "alias vim='nvim'" "$HOME/.aliases" 2>/dev/null; then
                echo "alias vim='nvim'" >> "$HOME/.aliases"
            fi
            echo "✔ 已添加 alias vim=nvim 到 .aliases"
        fi

        echo "✔ ZSH 配置已安装。"
    else
        echo "⏭ 跳过 ZSH 配置文件安装。"
    fi
    echo "------------------------------"

else
    echo "=== 开始安装 BASH 配置 ==="

    # --- [可选] 安装 Oh My Bash ---
    case "$PROFILE" in
        minimal) INSTALL_OMB="N" ;;
        full|desktop) INSTALL_OMB="Y" ;;
        *)
            printf "是否安装 Oh My Bash 框架? (y/N) "
            if read -t 10 INSTALL_OMB < /dev/tty; then :; else INSTALL_OMB="N"; echo ""; fi
            ;;
    esac

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
    if [[ "$TERM" == "xterm-ghostty" ]]; then
        if ! infocmp -a xterm-ghostty &>/dev/null; then
            export TERM=xterm-256color
        fi
    fi

    is_plain_env=false
    if [[ -n "$STARSHIP_PLAIN" && "$STARSHIP_PLAIN" != "0" ]]; then
        is_plain_env=true
    elif [[ "$TERM" =~ ^(linux|dumb|vt100|vt102|vt220|ansi)$ ]]; then
        is_plain_env=true
    elif [[ -n "$VNCDESKTOP" || -n "$VNC_PORT" || -n "$VNC_SOCKET" ]]; then
        is_plain_env=true
    elif [[ -n "$DISPLAY" && -z "$SSH_CONNECTION" && -z "$SSH_CLIENT" && "$TERM" != "xterm-ghostty" ]]; then
        is_plain_env=true
    elif [[ -z "$SSH_CONNECTION" && -z "$SSH_CLIENT" && "$TERM" =~ xterm && -z "$COLORTERM" && "$TERM" != "xterm-ghostty" ]]; then
        is_plain_env=true
    fi

    if [[ "$is_plain_env" == true && -f "$HOME/.config/starship-plain.toml" ]]; then
        export STARSHIP_CONFIG="$HOME/.config/starship-plain.toml"
    else
        unset STARSHIP_CONFIG
    fi
    eval "$(starship init bash)"
fi
EOF
        echo "✔ Oh My Bash starship 插件配置完成！"
    else
        echo "⏭ 跳过 Oh My Bash 安装。"
    fi
    echo "------------------------------"

    # --- [可选] 安装 Bash 现代 CLI 工具 ---
    echo "▶ 选择要安装的现代 CLI 工具："
    install_cli_tools "现代 CLI 工具安装 (Bash)" "ALL" "trash-cli" "ripgrep" "fd-find" "eza" "bat" "fzf" "zoxide" "gh" "btop" "SKIP"
    echo "------------------------------"

    # --- 安装 Bash 配置文件 ---
    printf "是否安装 Bash 配置文件 (.bashrc, .aliases, .login_info.sh)? (y/N) "
    if read -t 10 INSTALL_BASH_CONFIG < /dev/tty; then :; else INSTALL_BASH_CONFIG="N"; echo ""; fi

    if [[ "$INSTALL_BASH_CONFIG" =~ ^[Yy]$ ]]; then
        # 下载并替换自定义点文件
        echo "▶ 正在下载 .bashrc .aliases .login_info.sh..."
        get_config_file ".bashrc" "$HOME/.bashrc"
        get_config_file ".aliases" "$HOME/.aliases"
        get_config_file ".login_info.sh" "$HOME/.login_info.sh"
        
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

# --- 安装 Mise ---
case "$PROFILE" in
    minimal) INSTALL_MISE="N" ;;
    full|desktop) INSTALL_MISE="Y" ;;
    server) INSTALL_MISE="N" ;;
    *)
        printf "是否安装 Mise (开发环境工具版本管理器)? (y/N) "
        if read -t 10 INSTALL_MISE < /dev/tty; then :; else INSTALL_MISE="N"; echo ""; fi
        ;;
esac

if [[ "$INSTALL_MISE" =~ ^[Yy]$ ]]; then
    if command -v mise &>/dev/null; then
        echo "✔ mise 已安装，跳过 apt 安装。"
    else
        echo "▶ 正在通过 apt 安装 mise..."
        $SUDO apt-get update -y && $SUDO apt-get install -y gpg curl
        $SUDO install -dm 755 /etc/apt/keyrings
        curl -fSs https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | $SUDO tee /etc/apt/keyrings/mise-archive-keyring.gpg > /dev/null
        echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64,arm64,armhf] https://mise.jdx.dev/deb stable main" | $SUDO tee /etc/apt/sources.list.d/mise.list > /dev/null
        $SUDO apt-get update -y
        $SUDO apt-get install -y mise
    fi

    # 配置 shell 初始化
    if [[ "$INSTALL_SHELL" == "bash" ]] || [[ -f "$HOME/.bashrc" ]]; then
        if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'mise activate' "$HOME/.bashrc" 2>/dev/null; then
            echo '' >> "$HOME/.bashrc"
            echo '# Mise' >> "$HOME/.bashrc"
            echo 'eval "$(mise activate bash)"' >> "$HOME/.bashrc"
            echo "✔ 已配置 Bash Mise"
        fi
    fi

    if [[ "$INSTALL_SHELL" == "zsh" ]] || [[ -f "$HOME/.zshrc" ]]; then
        if [[ -f "$HOME/.zshrc" ]] && ! grep -q 'mise activate' "$HOME/.zshrc" 2>/dev/null; then
            echo '' >> "$HOME/.zshrc"
            echo '# Mise' >> "$HOME/.zshrc"
            echo 'eval "$(mise activate zsh)"' >> "$HOME/.zshrc"
            echo "✔ 已配置 Zsh Mise"
        fi
    fi

    if [[ "$INSTALL_SHELL" == "fish" ]] || [[ -f "$HOME/.config/fish/config.fish" ]]; then
        FISH_CONFIG="$HOME/.config/fish/config.fish"
        if [[ -f "$FISH_CONFIG" ]] && ! grep -q 'mise activate' "$FISH_CONFIG" 2>/dev/null; then
            cat >> "$FISH_CONFIG" << 'FISHEOF'

# Mise
if type -q mise
    mise activate fish | source
end
FISHEOF
            echo "✔ 已配置 Fish Mise"
        fi
    fi

    echo "✔ Mise 安装完成！"

    # --- 安装 Node.js (使用 mise) ---
    echo "▶ 选择要安装的 Node.js 版本："
    echo "  1) 最新 LTS 版本（推荐）"
    echo "  2) 指定版本号"
    echo "  3) 跳过"
    printf "请选择 (1/2/3，默认 3): "
    if read -t 15 NODE_CHOICE < /dev/tty; then :; else NODE_CHOICE="3"; echo ""; fi

    NODE_VERSION=""
    case "$NODE_CHOICE" in
        1)
            NODE_VERSION="lts"
            ;;
        2)
            printf "请输入版本号（如 20、22.0.0）: "
            if read -t 30 NODE_VERSION_INPUT < /dev/tty; then :; else NODE_VERSION_INPUT=""; echo ""; fi
            if [[ -z "$NODE_VERSION_INPUT" ]]; then
                echo "⚠ 未输入版本号，跳过 Node.js 安装。"
            else
                NODE_VERSION="$NODE_VERSION_INPUT"
            fi
            ;;
        *)
            echo "⏭ 跳过 Node.js 安装。"
            ;;
    esac

    if [[ -n "$NODE_VERSION" ]]; then
        eval "$(mise activate bash)" 2>/dev/null || true

        if [[ "$NODE_VERSION" == "lts" ]]; then
            echo "▶ 正在使用 mise 安装 Node.js lts..."
            mise use --global node@lts
        else
            echo "▶ 正在使用 mise 安装 Node.js $NODE_VERSION..."
            mise use --global "node@$NODE_VERSION"
        fi

        if command -v node &>/dev/null || mise exec -- node -v &>/dev/null; then
            echo "✔ Node.js 安装完成！"
        else
            echo "⚠ Node.js 安装可能失败，跳过 pnpm 安装。"
            NODE_VERSION=""
        fi
    fi

    if [[ -n "$NODE_VERSION" ]]; then
        # --- 安装 pnpm ---
        printf "是否安装 pnpm? (y/N) "
        if read -t 10 INSTALL_PNPM < /dev/tty; then :; else INSTALL_PNPM="N"; echo ""; fi

        if [[ "$INSTALL_PNPM" =~ ^[Yy]$ ]]; then
            echo "▶ 正在使用 mise 安装 pnpm..."
            mise use --global pnpm@latest
            echo "✔ pnpm 安装完成！"
        else
            echo "⏭ 跳过 pnpm 安装。"
        fi
    fi
else
    echo "⏭ 跳过 Mise 安装。"
fi
echo "------------------------------"

# --- 下载其他配置文件 ---
echo "▶ 正在配置其他配置文件..."

# Git 配置
case "$PROFILE" in
    minimal) INSTALL_GIT_CONFIG="N" ;;
    full|desktop|server) INSTALL_GIT_CONFIG="Y" ;;
    *)
        printf "是否安装 Git 配置 (.gitconfig)? (y/N) "
        if read -t 10 INSTALL_GIT_CONFIG < /dev/tty; then :; else INSTALL_GIT_CONFIG="N"; echo ""; fi
        ;;
esac

if [[ "$INSTALL_GIT_CONFIG" =~ ^[Yy]$ ]]; then
    echo "▶ 正在配置 Git 配置..."
    get_config_file ".gitconfig" "$HOME/.gitconfig"
    echo "✔ Git 配置已安装。"
else
    echo "⏭ 跳过 Git 配置。"
fi

# Kitty 配置
case "$PROFILE" in
    minimal|server) INSTALL_KITTY="N" ;;
    full|desktop) INSTALL_KITTY="Y" ;;
    *)
        printf "是否安装 Kitty 配置 (current-theme.conf, kitty.conf)? (y/N) "
        if read -t 10 INSTALL_KITTY < /dev/tty; then :; else INSTALL_KITTY="N"; echo ""; fi
        ;;
esac
if [[ "$INSTALL_KITTY" =~ ^[Yy]$ ]]; then
    echo "▶ 正在下载 Kitty 配置..."
    mkdir -p "$HOME/.config/kitty"
    get_config_file ".config/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"
    get_config_file ".config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    echo "✔ Kitty 配置已安装。"
else
    echo "⏭ 跳过 Kitty 配置。"
fi

# Ghostty 配置
case "$PROFILE" in
    minimal|server) INSTALL_GHOSTTY="N" ;;
    full|desktop) INSTALL_GHOSTTY="Y" ;;
    *)
        printf "是否安装 Ghostty 配置? (y/N) "
        if read -t 10 INSTALL_GHOSTTY < /dev/tty; then :; else INSTALL_GHOSTTY="N"; echo ""; fi
        ;;
esac
if [[ "$INSTALL_GHOSTTY" =~ ^[Yy]$ ]]; then
    echo "▶ 正在下载 Ghostty 配置..."
    mkdir -p "$HOME/.config/ghostty/auto"
    # 下载主配置文件
    get_config_file ".config/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
    # 下载主题配置文件
    get_config_file ".config/ghostty/auto/theme.ghostty" "$HOME/.config/ghostty/auto/theme.ghostty"
    echo "✔ Ghostty 配置已安装。"
else
    echo "⏭ 跳过 Ghostty 配置。"
fi

###
# Docker 与 Docker 用户组配置
###
echo "=== Docker 配置 ==="

# 1. 检查或安装 Docker
if command -v docker &> /dev/null; then
    echo "✔ 检测到 Docker 已安装: $(docker --version 2>/dev/null | head -n1)"
else
    if [[ "$IS_PVE_LXC" == true ]]; then
        echo "ℹ 提示: 当前处于 PVE LXC 容器环境。"
        echo "  在 PVE LXC 中运行 Docker 需要在 PVE 宿主机开启此容器的 Nesting (嵌套) 与 keyctl。"
    fi

    case "$PROFILE" in
        minimal) INSTALL_DOCKER="N" ;;
        full|server) INSTALL_DOCKER="Y" ;;
        *)
            printf "未检测到 Docker，是否安装 Docker? (y/N) "
            if read -t 15 INSTALL_DOCKER < /dev/tty; then :; else INSTALL_DOCKER="N"; echo ""; fi
            ;;
    esac

    if [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
        echo "▶ 正在使用官方脚本安装 Docker..."
        TEMP_DOCKER_SH=$(mktemp)
        TEMP_FILES+=("$TEMP_DOCKER_SH")
        if curl -fsSL https://get.docker.com -o "$TEMP_DOCKER_SH"; then
            $SUDO sh "$TEMP_DOCKER_SH" || echo "⚠ Docker 安装脚本执行异常，后续配置将继续尝试。"
            rm -f "$TEMP_DOCKER_SH"
            if command -v docker &> /dev/null; then
                echo "✔ Docker 安装成功: $(docker --version 2>/dev/null | head -n1)"
            else
                echo "❌ Docker 安装可能未完成。"
            fi
        else
            echo "❌ 下载 Docker 官方安装脚本失败。"
        fi
    else
        echo "⏭ 跳过 Docker 安装。"
    fi
fi

# 2. Docker 用户组配置（无论系统有无安装 Docker，无论是否安装，均询问）
TARGET_USER="${CURRENT_USER:-$(whoami)}"
if [[ "$TARGET_USER" == "root" && -n "$SUDO_USER" ]]; then
    TARGET_USER="$SUDO_USER"
fi

if [[ "$TARGET_USER" != "root" ]]; then
    if id -nG "$TARGET_USER" 2>/dev/null | grep -qw "docker"; then
        echo "✔ 用户 $TARGET_USER 已在 docker 用户组中。"
    else
        printf "是否添加用户 %s 到 docker 用户组 (免 sudo 运行 docker)? (y/N) " "$TARGET_USER"
        if read -t 15 ADD_DOCKER_GRP < /dev/tty; then :; else ADD_DOCKER_GRP="N"; echo ""; fi

        if [[ "$ADD_DOCKER_GRP" =~ ^[Yy]$ ]]; then
            if ! getent group docker > /dev/null 2>&1; then
                echo "▶ 创建 docker 用户组..."
                $SUDO groupadd docker
            fi
            echo "▶ 添加用户 $TARGET_USER 到 docker 组..."
            $SUDO usermod -aG docker "$TARGET_USER"
            echo "✔ 用户 $TARGET_USER 已成功添加到 docker 组 (注销并重新登录终端后生效)。"
        else
            echo "⏭ 跳过添加 docker 用户组。"
        fi
    fi
else
    echo "ℹ 当前为 root 用户，无需配置普通用户 docker 组免 sudo。"
fi

# 3. Docker 守护进程配置 (daemon.json)
case "$PROFILE" in
    minimal) INSTALL_DOCKER_CONFIG="N" ;;
    full|server) INSTALL_DOCKER_CONFIG="Y" ;;
    *)
        printf "是否配置 Docker 守护进程 (daemon.json)? (y/N) "
        if read -t 10 INSTALL_DOCKER_CONFIG < /dev/tty; then :; else INSTALL_DOCKER_CONFIG="N"; echo ""; fi
        ;;
esac

if [[ "$INSTALL_DOCKER_CONFIG" =~ ^[Yy]$ ]]; then
    echo "▶ 正在配置 Docker 守护进程..."
    $SUDO mkdir -p /etc/docker
    TEMP_JSON=$(mktemp)
    TEMP_FILES+=("$TEMP_JSON")

    # 复用统一函数：本地模式 cp，在线模式 curl
    if ! get_config_file "etc/docker/daemon.json" "$TEMP_JSON"; then
        echo "⚠ 获取 Docker 配置文件失败，跳过。"
        TEMP_JSON=""
    fi

    if [[ -n "$TEMP_JSON" ]] && [[ -s "$TEMP_JSON" ]]; then
        if [ -f "/etc/docker/daemon.json" ]; then
            echo "ℹ 发现现有 daemon.json，正在合并配置..."
            if command -v jq &> /dev/null; then
                $SUDO cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%Y%m%d_%H%M%S)
                $SUDO jq -s '.[0] * .[1]' /etc/docker/daemon.json "$TEMP_JSON" | $SUDO tee "$TEMP_JSON.merged" > /dev/null
                $SUDO mv "$TEMP_JSON.merged" /etc/docker/daemon.json
            else
                echo "⚠ 未检测到 jq，无法合并 Docker 配置，备份原配置后直接替换。"
                $SUDO cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%Y%m%d_%H%M%S)
                $SUDO mv "$TEMP_JSON" /etc/docker/daemon.json
                $SUDO chmod 644 /etc/docker/daemon.json
                TEMP_JSON=""
            fi
        else
            echo "ℹ 未发现 daemon.json，正在创建..."
            $SUDO mv "$TEMP_JSON" /etc/docker/daemon.json
            $SUDO chmod 644 /etc/docker/daemon.json
        fi
        echo "✔ Docker 守护进程配置已更新。"
    else
        echo "⚠ 无法下载 Docker 配置，跳过。"
    fi
else
    echo "⏭ 跳过 Docker 守护进程配置。"
fi

echo "------------------------------"

###
# SSH 配置（仅适用于 VPS 环境）
###
case "$PROFILE" in
    minimal) CONFIGURE_SSH="N" ;;
    server) CONFIGURE_SSH="Y" ;;
    *)
        printf "是否配置 SSH 服务 (仅在 VPS 环境推荐配置)? (y/N) "
        if read -t 10 CONFIGURE_SSH < /dev/tty; then :; else CONFIGURE_SSH="N"; echo ""; fi
        ;;
esac

if [[ "$CONFIGURE_SSH" =~ ^[Yy]$ ]]; then
    echo "▶ 开始配置 SSH 服务..."

    # 检查 SSH 服务状态
    if ! systemctl is-active --quiet ssh && ! systemctl is-active --quiet sshd; then
        echo "▶ 启用 SSH 服务..."
        $SUDO systemctl enable ssh 2>/dev/null || $SUDO systemctl enable sshd 2>/dev/null || true
        $SUDO systemctl start ssh 2>/dev/null || $SUDO systemctl start sshd 2>/dev/null || true
    fi

    echo "▶ 系统版本: $DISTRO_NAME $DISTRO_VERSION"

    # 选择 SSH 端口
    echo "请选择 SSH 端口配置方式:"
    echo "  1) 输入自定义端口"
    echo "  2) 使用 50000 以上的随机端口"
    printf "请选择 (1/2): "
    if read -t 30 PORT_CHOICE < /dev/tty; then :; else PORT_CHOICE="2"; echo ""; fi

    case $PORT_CHOICE in
        1)
            tput cnorm 2>/dev/null || true
            printf "请输入 SSH 端口 (22-65535): "
            read -t 30 SSH_PORT < /dev/tty
            if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 22 ] || [ "$SSH_PORT" -gt 65535 ]; then
                echo "❌ 无效端口，使用默认端口 22"
                SSH_PORT=22
            fi
            ;;
        2)
            SSH_PORT=$((50000 + RANDOM % 15536))  # 50000-65535
            echo "▶ 随机生成端口: $SSH_PORT"
            ;;
        *)
            SSH_PORT=$((50000 + RANDOM % 15536))
            echo "▶ 默认使用随机端口: $SSH_PORT"
            ;;
    esac

    # 是否禁用 root 直接登录
    printf "是否禁用 root 用户直接 SSH 登录? (y/N) "
    if read -t 10 DISABLE_ROOT_SSH < /dev/tty; then :; else DISABLE_ROOT_SSH="N"; echo ""; fi

    # 是否禁止密码登录
    printf "是否禁止密码登录 (推荐使用密钥登录)? (y/N) "
    if read -t 10 DISABLE_PASSWORD_AUTH < /dev/tty; then :; else DISABLE_PASSWORD_AUTH="N"; echo ""; fi

    # SSH 公钥配置交互（提供 3 种选择）
    SSH_KEY_CONTENT=""
    echo ""
    echo "请选择 SSH 公钥配置方式:"
    echo "  1) 从 GitHub 导入公钥"
    echo "  2) 本机生成公钥私钥对 (生成后需备份私钥)"
    echo "  3) 手动粘贴公钥"
    echo "  4) 跳过公钥配置"
    tput cnorm 2>/dev/null || true
    printf "请选择 (1/2/3/4，默认 4): "
    if read -t 30 SSH_KEY_CHOICE < /dev/tty; then :; else SSH_KEY_CHOICE="4"; echo ""; fi

    case "$SSH_KEY_CHOICE" in
        1)
            echo "▶ 方式一：从 GitHub 导入公钥"
            tput cnorm 2>/dev/null || true
            printf "请输入 GitHub 用户名: "
            read -r GITHUB_USERNAME < /dev/tty
            if [[ -z "$GITHUB_USERNAME" ]]; then
                echo "❌ GitHub 用户名不能为空，跳过公钥配置。"
            else
                echo "▶ 正在从 https://github.com/${GITHUB_USERNAME}.keys 获取公钥..."
                GH_KEYS=$(curl -fsSL "https://github.com/${GITHUB_USERNAME}.keys" 2>/dev/null || true)
                VALID_KEYS=$(echo "$GH_KEYS" | grep -E '^(ssh-(rsa|ed25519)|ecdsa-|sk-)' || true)
                if [[ -n "$VALID_KEYS" ]]; then
                    KEY_COUNT=$(echo "$VALID_KEYS" | grep -c -E '^(ssh-(rsa|ed25519)|ecdsa-|sk-)')
                    echo "✔ 成功从 GitHub 获取到 $KEY_COUNT 个有效公钥。"
                    SSH_KEY_CONTENT="$VALID_KEYS"
                else
                    echo "❌ 未能在 GitHub 上找到用户 $GITHUB_USERNAME 的有效公钥。"
                fi
            fi
            ;;
        2)
            echo "▶ 方式二：生成公钥与私钥对"
            TEMP_KEY_DIR=$(mktemp -d)
            TEMP_FILES+=("$TEMP_KEY_DIR")
            KEY_PATH="$TEMP_KEY_DIR/id_ed25519"
            KEY_COMMENT="${TARGET_USER}@$(hostname)-$(date +%Y%m%d)"
            if ssh-keygen -t ed25519 -C "$KEY_COMMENT" -N "" -f "$KEY_PATH" > /dev/null 2>&1; then
                SSH_KEY_CONTENT=$(cat "${KEY_PATH}.pub")
                echo ""
                echo "============================================================"
                echo "⚠️  私钥已生成！请务必立即复制并保存以下私钥："
                echo "   （将其保存至本地计算机，例如 ~/.ssh/id_ed25519，权限设为 600）"
                echo "============================================================"
                cat "$KEY_PATH"
                echo "============================================================"
                echo ""
                tput cnorm 2>/dev/null || true
                printf "请确认已备份私钥后按回车键继续...: "
                read -r _ < /dev/tty
                shred -u "$KEY_PATH" 2>/dev/null || rm -f "$KEY_PATH"
                rm -rf "$TEMP_KEY_DIR"
                echo "✔ 私钥备份确认完成，公钥已就绪。"
            else
                echo "❌ 密钥对生成失败。"
            fi
            ;;
        3)
            echo "▶ 方式三：手动粘贴公钥"
            echo "提示: 公钥以 ssh-ed25519, ssh-rsa, ecdsa-* 等开头"
            tput cnorm 2>/dev/null || true
            printf "SSH 公钥: "
            read -r SSH_KEY_INPUT < /dev/tty
            if [[ -z "$SSH_KEY_INPUT" ]] || ! [[ "$SSH_KEY_INPUT" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-|sk-) ]]; then
                echo "❌ 无效的 SSH 公钥格式，跳过公钥配置。"
            else
                SSH_KEY_CONTENT="$SSH_KEY_INPUT"
                echo "✔ 公钥录入成功。"
            fi
            ;;
        *)
            echo "⏭ 跳过公钥配置。"
            ;;
    esac

    # 写入公钥与设置权限 (必须保证 ~/.ssh 700, authorized_keys 600)
    if [[ -n "$SSH_KEY_CONTENT" ]]; then
        echo "▶ 写入公钥并设置目录与文件权限..."
        TARGET_USERS_LIST=()
        if [[ "$EUID" -eq 0 ]]; then
            TARGET_USERS_LIST+=("root")
            if [[ -n "$USERNAME" && "$USERNAME" != "root" ]]; then
                TARGET_USERS_LIST+=("$USERNAME")
            fi
        else
            TARGET_USERS_LIST+=("$CURRENT_USER")
            if [[ "$DISABLE_ROOT_SSH" != "Y" && "$DISABLE_ROOT_SSH" != "y" ]]; then
                TARGET_USERS_LIST+=("root")
            fi
        fi

        for u in "${TARGET_USERS_LIST[@]}"; do
            local u_home=""
            if [[ "$u" == "root" ]]; then
                u_home="/root"
            else
                u_home=$(eval echo "~$u")
            fi

            if [[ -d "$u_home" ]]; then
                $SUDO mkdir -p "$u_home/.ssh"
                AUTH_KEYS="$u_home/.ssh/authorized_keys"

                if ! $SUDO test -f "$AUTH_KEYS"; then
                    $SUDO touch "$AUTH_KEYS"
                fi

                while IFS= read -r key_line; do
                    [[ -z "$key_line" ]] && continue
                    if ! $SUDO grep -Fxq "$key_line" "$AUTH_KEYS" 2>/dev/null; then
                        echo "$key_line" | $SUDO tee -a "$AUTH_KEYS" > /dev/null
                    fi
                done <<< "$SSH_KEY_CONTENT"

                $SUDO chmod 700 "$u_home/.ssh"
                $SUDO chmod 600 "$AUTH_KEYS"
                if [[ "$u" != "root" ]]; then
                    $SUDO chown -R "$u:$u" "$u_home/.ssh"
                else
                    $SUDO chown -R root:root "$u_home/.ssh"
                fi
                echo "✔ 用户 $u: ~/.ssh (权限 700) 与 authorized_keys (权限 600) 设置完成"
            fi
        done
    else
        if [[ "$DISABLE_PASSWORD_AUTH" =~ ^[Yy]$ ]]; then
            echo "⚠️  警告: 未配置任何有效 SSH 公钥！为防止锁在服务器外，自动保持密码登录开启。"
            DISABLE_PASSWORD_AUTH="N"
        fi
    fi

    # 判定是否使用现代化配置方式 (sshd_config.d/)
    USE_SSHD_CONFIG_D=false
    if [ -d /etc/ssh/sshd_config.d ] || [[ "$IS_MODERN_SYSTEM" == true ]] || grep -q 'Include /etc/ssh/sshd_config.d/' /etc/ssh/sshd_config 2>/dev/null; then
        USE_SSHD_CONFIG_D=true
    fi

    if [[ "$USE_SSHD_CONFIG_D" == true ]]; then
        echo "▶ 使用现代化配置方式 (/etc/ssh/sshd_config.d/)..."
        $SUDO mkdir -p /etc/ssh/sshd_config.d

        CONFIG_FILE="/etc/ssh/sshd_config.d/99-custom.conf"
        cat << EOF | $SUDO tee "$CONFIG_FILE" > /dev/null
# Custom SSH configuration added by dotfiles setup
Port $SSH_PORT
AcceptEnv LANG LC_* TERM_PROGRAM COLORTERM
EOF

        if [[ "$DISABLE_ROOT_SSH" =~ ^[Yy]$ ]]; then
            echo "PermitRootLogin no" | $SUDO tee -a "$CONFIG_FILE" > /dev/null
        fi

        if [[ "$DISABLE_PASSWORD_AUTH" =~ ^[Yy]$ ]]; then
            cat << EOF | $SUDO tee -a "$CONFIG_FILE" > /dev/null
PasswordAuthentication no
PubkeyAuthentication yes
EOF
        fi

        $SUDO chmod 644 "$CONFIG_FILE"

        # 确保主配置文件包含 Include 指令
        if [ -f /etc/ssh/sshd_config ] && ! grep -q 'Include /etc/ssh/sshd_config.d/\*.conf' /etc/ssh/sshd_config; then
            echo "Include /etc/ssh/sshd_config.d/*.conf" | $SUDO tee -a /etc/ssh/sshd_config > /dev/null
        fi
    else
        echo "▶ 使用传统配置方式 (直接修改 /etc/ssh/sshd_config)..."
        SSHD_CONFIG="/etc/ssh/sshd_config"
        $SUDO cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%Y%m%d_%H%M%S)"

        $SUDO sed -i "s/^#*Port .*/Port $SSH_PORT/" "$SSHD_CONFIG"
        if ! grep -q "^Port $SSH_PORT" "$SSHD_CONFIG"; then
            echo "Port $SSH_PORT" | $SUDO tee -a "$SSHD_CONFIG" > /dev/null
        fi

        if [[ "$DISABLE_ROOT_SSH" =~ ^[Yy]$ ]]; then
            $SUDO sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' "$SSHD_CONFIG"
        fi

        if [[ "$DISABLE_PASSWORD_AUTH" =~ ^[Yy]$ ]]; then
            $SUDO sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' "$SSHD_CONFIG"
            $SUDO sed -i 's/^#*PubkeyAuthentication .*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
        fi
    fi

    # 处理 Ubuntu 22.10 / 24.04 / 26.04+ 及现代系统的 systemd ssh.socket
    if systemctl is-active --quiet ssh.socket 2>/dev/null || systemctl is-enabled --quiet ssh.socket 2>/dev/null; then
        echo "▶ 检测到 systemd ssh.socket 机制，配置 socket 监听端口..."
        $SUDO mkdir -p /etc/systemd/system/ssh.socket.d
        cat << EOF | $SUDO tee /etc/systemd/system/ssh.socket.d/listen.conf > /dev/null
[Socket]
ListenStream=
ListenStream=$SSH_PORT
EOF
        $SUDO systemctl daemon-reload
        $SUDO systemctl restart ssh.socket 2>/dev/null || true
    fi

    # 重启 SSH 服务
    echo "▶ 重启 SSH 服务..."
    if systemctl list-unit-files 2>/dev/null | grep -q "^ssh\.service"; then
        $SUDO systemctl restart ssh 2>/dev/null || true
    elif systemctl list-unit-files 2>/dev/null | grep -q "^sshd\.service"; then
        $SUDO systemctl restart sshd 2>/dev/null || true
    fi

    # 验证端口监听
    echo "▶ 检查 SSH 服务端口监听状态 (端口: $SSH_PORT)..."
    sleep 1
    PORT_ACTIVE=false
    if command -v ss &>/dev/null; then
        if ss -tln | grep -q ":$SSH_PORT "; then PORT_ACTIVE=true; fi
    fi
    if [[ "$PORT_ACTIVE" == false ]] && timeout 3 bash -c "</dev/tcp/127.0.0.1/$SSH_PORT" 2>/dev/null; then
        PORT_ACTIVE=true
    fi

    if [[ "$PORT_ACTIVE" == true ]]; then
        echo "✔ SSH 端口 $SSH_PORT 已正常处于监听状态！"
    else
        echo "⚠ 提示: 端口 $SSH_PORT 尚未检测到连接响应（可能受防火墙或异步启动影响）。"
        echo "   建议在保持当前会话的同时，新开窗口测试连接。"
    fi

    # 显示配置结果
    echo "------------------------------"
    echo "✅ SSH 配置完成！"
    echo "🔧 配置详情:"
    echo "   • SSH 端口: $SSH_PORT"
    if [[ "$DISABLE_ROOT_SSH" =~ ^[Yy]$ ]]; then
        echo "   • Root 登录: 已禁用"
    else
        echo "   • Root 登录: 已启用"
    fi
    if [[ "$DISABLE_PASSWORD_AUTH" =~ ^[Yy]$ ]]; then
        echo "   • 密码登录: 已禁用 (仅密钥登录)"
    else
        echo "   • 密码登录: 已启用"
    fi
    echo ""
    echo "⚠️  重要提醒:"
    echo "   • 请务必在新终端测试新配置能否正常连接后再关闭当前会话！"
    echo "   • 测试命令: ssh -p $SSH_PORT $(whoami)@<服务器IP>"
    echo "------------------------------"

else
    echo "⏭ 跳过 SSH 配置。"
fi

echo "------------------------------"

###
# 防火墙和安全工具配置
###
echo "▶ 安全工具配置..."

# UFW 防火墙配置
case "$PROFILE" in
    minimal) INSTALL_UFW="N" ;;
    server) INSTALL_UFW="Y" ;;
    *)
        printf "是否安装并配置 UFW 防火墙? (y/N) "
        if read -t 10 INSTALL_UFW < /dev/tty; then :; else INSTALL_UFW="N"; echo ""; fi
        ;;
esac

if [[ "$INSTALL_UFW" =~ ^[Yy]$ ]]; then
    # PVE LXC 环境检测与提示
    if [[ "$IS_PVE_LXC" == true ]]; then
        echo "ℹ 检测到当前处于 PVE LXC 容器环境。"
        if ! $SUDO iptables -L -n &>/dev/null; then
            echo "⚠ 当前容器环境未检测到可用的内核 iptables/netfilter 模块。"
            echo "  在非特权 LXC 容器中强制启用 UFW 可能会导致启动失败或网络中断。"
            echo "  推荐直接在 PVE 宿主机或 PVE 管理界面的防火墙规则中进行防护。"
            printf "是否仍要尝试在容器内配置 UFW? (y/N) "
            if read -t 10 FORCE_UFW < /dev/tty; then :; else FORCE_UFW="N"; echo ""; fi
            if ! [[ "$FORCE_UFW" =~ ^[Yy]$ ]]; then
                INSTALL_UFW="N"
                echo "⏭ 已针对 PVE LXC 环境安全跳过 UFW。"
            fi
        fi
    fi
fi

if [[ "$INSTALL_UFW" =~ ^[Yy]$ ]]; then
    if command -v ufw &>/dev/null; then
        echo "✔ UFW 已安装，跳过安装。"
    else
        echo "▶ 正在安装 UFW..."
        $SUDO apt-get install -y ufw
    fi
    
    echo "▶ 配置 UFW 默认规则..."
    # 设置默认策略
    $SUDO ufw default deny incoming
    $SUDO ufw default allow outgoing
    
    # 允许 SSH（使用前面配置的端口）
    if [[ -n "$SSH_PORT" && "$SSH_PORT" != "22" ]]; then
        $SUDO ufw allow "$SSH_PORT"/tcp
    else
        $SUDO ufw allow ssh
    fi
    
    # 启用 UFW
    $SUDO ufw --force enable || echo "⚠ UFW 启用出现警告，请检查内核模块支持"
    echo "✔ UFW 防火墙已配置完成"
    echo "   • 默认策略: 禁止所有入站流量，允许所有出站流量"
    echo "   • 已允许端口: ${SSH_PORT:-22}/tcp"
else
    echo "⏭ 跳过 UFW 安装。"
fi
echo "------------------------------"

# UFW Docker 配置
case "$PROFILE" in
    minimal|desktop) INSTALL_UFW_DOCKER="N" ;;
    server) INSTALL_UFW_DOCKER="Y" ;;
    *)
        printf "是否安装 UFW Docker 集成 (ufw-docker)? (y/N) "
        if read -t 10 INSTALL_UFW_DOCKER < /dev/tty; then :; else INSTALL_UFW_DOCKER="N"; echo ""; fi
        ;;
esac

if [[ "$INSTALL_UFW_DOCKER" =~ ^[Yy]$ ]]; then
    if ! command -v docker &> /dev/null; then
        echo "⏭ 未检测到 Docker，跳过 UFW Docker 安装。"
    else
        echo "▶ 正在安装 UFW Docker..."
        
        # 下载 ufw-docker 脚本
        $SUDO wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
        $SUDO chmod +x /usr/local/bin/ufw-docker
        
        # 修改 UFW 配置以支持 Docker
        if $SUDO grep -q "# ufw-docker" /etc/ufw/after.rules 2>/dev/null; then
            echo "⏭ UFW Docker 规则已存在，跳过添加。"
        else
            echo "▶ 添加 UFW Docker 规则..."
            cat << 'EOF' | $SUDO tee -a /etc/ufw/after.rules > /dev/null

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
        fi
        
        # 重新加载 UFW
        if [[ "$INSTALL_UFW" =~ ^[Yy]$ ]] || command -v ufw &> /dev/null; then
            $SUDO ufw reload 2>/dev/null || true
        fi
        
        echo "✔ UFW Docker 已安装"
        echo "   • 用法: ufw-docker allow <service_name>"
        echo "   • 示例: ufw-docker allow nginx"
    fi
else
    echo "⏭ 跳过 UFW Docker 安装。"
fi
echo "------------------------------"

# Fail2ban 配置
case "$PROFILE" in
    minimal|desktop) INSTALL_FAIL2BAN="N" ;;
    server) INSTALL_FAIL2BAN="Y" ;;
    *)
        printf "是否安装 Fail2ban (SSH 暴力破解防护)? (y/N) "
        if read -t 10 INSTALL_FAIL2BAN < /dev/tty; then :; else INSTALL_FAIL2BAN="N"; echo ""; fi
        ;;
esac

if [[ "$INSTALL_FAIL2BAN" =~ ^[Yy]$ ]]; then
    # PVE LXC 环境提示
    if [[ "$IS_PVE_LXC" == true ]]; then
        if ! $SUDO iptables -L -n &>/dev/null; then
            echo "⚠ 提示: 当前 PVE LXC 容器环境受限，Fail2ban 在无内核 netfilter 权限时将无法生效。"
        fi
    fi

    if command -v fail2ban-client &>/dev/null; then
        echo "✔ Fail2ban 已安装，跳过安装。"
    else
        echo "▶ 正在安装 Fail2ban..."
        $SUDO apt-get install -y fail2ban python3-systemd 2>/dev/null || $SUDO apt-get install -y fail2ban
    fi
    
    echo "▶ 配置 Fail2ban..."
    
    # 现代化系统 (如 Debian 12/13, Ubuntu 24.04/26.04) 默认无 rsyslog (/var/log/auth.log 不存在)
    # 此时应使用 systemd 后端
    FAIL2BAN_BACKEND_CONF=""
    if [ ! -f /var/log/auth.log ]; then
        FAIL2BAN_BACKEND_CONF="backend = systemd"
    else
        FAIL2BAN_BACKEND_CONF="logpath = /var/log/auth.log"
    fi

    FAIL2BAN_PORT="${SSH_PORT:-ssh}"

    # 创建本地配置文件
    cat << EOF | $SUDO tee /etc/fail2ban/jail.local > /dev/null
[DEFAULT]
# 禁用时间（秒）: 30 分钟
bantime = 1800
# 检查间隔（秒）
findtime = 600
# 在 findtime 内最大失败次数
maxretry = 5

[sshd]
enabled = true
port = $FAIL2BAN_PORT
$FAIL2BAN_BACKEND_CONF
maxretry = 5
bantime = 1800
findtime = 600

[sshd-ddos]
enabled = true
port = $FAIL2BAN_PORT
$FAIL2BAN_BACKEND_CONF
maxretry = 10
bantime = 600
findtime = 600
action = %(action_)s
EOF

    # 启动 Fail2ban
    $SUDO systemctl enable fail2ban 2>/dev/null || true
    $SUDO systemctl restart fail2ban 2>/dev/null || true
    
    echo "✔ Fail2ban 已配置完成"
    echo "   • 监控端口: $FAIL2BAN_PORT"
    echo "   • 禁用时间: 30 分钟"
    echo "   • 最大失败次数: 5 次 (30 分钟内)"
    echo "   • DDoS 防护: 最多 10 次失败后禁用 10 分钟"
    echo ""
    echo "📋 常用命令:"
    echo "   • 查看 fail2ban 状态: sudo fail2ban-client status"
    echo "   • 查看 sshd 监狱: sudo fail2ban-client status sshd"
    echo "   • 手动解封 IP: sudo fail2ban-client set sshd unbanip <IP>"
else
    echo "⏭ 跳过 Fail2ban 安装。"
fi

echo "------------------------------"
echo "=== 配置完成！==="
echo "请重启你的终端或运行以下命令以应用所有更改："

if [[ "$INSTALL_SHELL" == "fish" ]]; then
    echo "exec fish"
    echo ""
    echo "提示：如果你想让 Fish 成为默认 shell，请运行："
    echo "chsh -s \$(which fish)"
elif [[ "$INSTALL_SHELL" == "zsh" ]]; then
    echo "exec zsh"
    echo ""
    echo "提示：如果你想让 Zsh 成为默认 shell，请运行："
    echo "chsh -s \$(which zsh)"
else
    echo "source ~/.bashrc"
fi

echo ""
echo "$INSTALL_SHELL 环境配置完成。"

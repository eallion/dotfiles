#!/bin/bash
#
# 在线安装脚本入口点
# 用法: curl -sSL https://s.e5n.cc/dotfiles | bash
#       curl -sSL https://s.e5n.cc/dotfiles | bash -s -- zsh
#       curl -sSL https://s.e5n.cc/dotfiles | bash -s -- fish
#
# 此脚本从网络下载 setup.sh 并执行，安装模式自动为在线模式
#

SHELL_TYPE=""
PROFILE=""

for arg in "$@"; do
    case "$arg" in
        bash|zsh|fish)
            SHELL_TYPE="$arg"
            ;;
        --minimal|minimal|--full|full|--server|server|--desktop|desktop)
            PROFILE="$arg"
            ;;
        *)
            echo "❌ 错误: 未知参数 '$arg'"
            echo "支持的 Shell: bash, zsh, fish"
            echo "支持的模式: --minimal, --full, --server, --desktop"
            echo "用法: $0 [bash|zsh|fish] [--minimal|--full|--server|--desktop]"
            exit 1
            ;;
    esac
done

echo "=== 在线安装模式 ==="
if [[ -n "$SHELL_TYPE" ]]; then
    echo "Shell 类型: $SHELL_TYPE"
else
    echo "Shell 类型: 交互选择 / 自动检测"
fi
[[ -n "$PROFILE" ]] && echo "安装配置: $PROFILE"
echo "------------------------------"

# 下载 setup.sh 到临时文件
TEMP_SETUP=$(mktemp)
trap "rm -f $TEMP_SETUP" EXIT

echo "▶ 正在下载配置脚本..."
curl -sSL "https://raw.githubusercontent.com/eallion/dotfiles/refs/heads/main/setup.sh" -o "$TEMP_SETUP"

if [[ ! -s "$TEMP_SETUP" ]]; then
    echo "❌ 错误: 无法下载 setup.sh"
    exit 1
fi

# 执行下载的 setup.sh，不传递第二个参数（表示在线模式）
bash "$TEMP_SETUP" "$SHELL_TYPE" "" "$PROFILE"

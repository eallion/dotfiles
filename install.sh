#!/bin/bash
#
# 本地安装脚本入口点
# 注意：本脚本专为 Debian / Ubuntu (Deb 系) 系统设计，仅支持 Deb 系 Linux 发行版
# 用法: ./install.sh [bash|zsh|fish] [--minimal|--full|--server|--desktop]
#       ./install.sh --rollback
#       ./install.sh --clean-backup
#

# 回滚模式
if [[ "$1" == "--rollback" || "$1" == "-r" ]]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    exec bash "$SCRIPT_DIR/setup.sh" --rollback
fi

# 清除备份模式
if [[ "$1" == "--clean-backup" || "$1" == "-c" ]]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    exec bash "$SCRIPT_DIR/setup.sh" --clean-backup
fi

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

echo "=== 本地安装模式 ==="
if [[ -n "$SHELL_TYPE" ]]; then
    echo "Shell 类型: $SHELL_TYPE"
else
    echo "Shell 类型: 交互选择 / 自动检测"
fi
[[ -n "$PROFILE" ]] && echo "安装配置: $PROFILE"
echo "------------------------------"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

exec bash "$SCRIPT_DIR/setup.sh" "$SHELL_TYPE" "local" "$PROFILE"

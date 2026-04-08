#!/bin/bash
#
# 本地安装脚本入口点
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

SHELL_TYPE=${1:-bash}
PROFILE="${2:-}"

if [[ "$SHELL_TYPE" != "bash" && "$SHELL_TYPE" != "zsh" && "$SHELL_TYPE" != "fish" ]]; then
    echo "❌ 错误: 不支持的 shell 类型 '$SHELL_TYPE'"
    echo "支持的类型: bash, zsh, fish"
    echo "用法: $0 [bash|zsh|fish] [--minimal|--full|--server|--desktop]"
    exit 1
fi

echo "=== 本地安装模式 ==="
echo "Shell 类型: $SHELL_TYPE"
[[ -n "$PROFILE" ]] && echo "安装配置: $PROFILE"
echo "------------------------------"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

exec bash "$SCRIPT_DIR/setup.sh" "$SHELL_TYPE" "local" "$PROFILE"

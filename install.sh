#!/bin/bash
#
# 本地安装脚本入口点
# 用法: ./install.sh [bash|zsh]
# 如果不指定参数，默认安装 bash 配置
#

# 获取参数，如果没有参数则默认为 bash
SHELL_TYPE=${1:-bash}

# 验证参数
if [[ "$SHELL_TYPE" != "bash" && "$SHELL_TYPE" != "zsh" ]]; then
    echo "❌ 错误: 不支持的 shell 类型 '$SHELL_TYPE'"
    echo "支持的类型: bash, zsh"
    echo "用法: $0 [bash|zsh]"
    exit 1
fi

echo "=== 本地安装模式 ==="
echo "Shell 类型: $SHELL_TYPE"
echo "------------------------------"

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 直接执行本地的 setup.sh，传递参数
exec bash "$SCRIPT_DIR/setup.sh" "$SHELL_TYPE"
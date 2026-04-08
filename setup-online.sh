#!/bin/bash
#
# 在线安装脚本入口点
# 用法: curl -sSL https://s.e5n.cc/dotfiles | bash
#       curl -sSL https://s.e5n.cc/dotfiles | bash -s -- zsh
#       curl -sSL https://s.e5n.cc/dotfiles | bash -s -- fish
#
# 此脚本从网络下载 setup.sh 并执行，安装模式自动为在线模式
#

# 获取参数，如果没有参数则默认为 bash
SHELL_TYPE=${1:-bash}

# 验证参数
if [[ "$SHELL_TYPE" != "bash" && "$SHELL_TYPE" != "zsh" && "$SHELL_TYPE" != "fish" ]]; then
    echo "❌ 错误: 不支持的 shell 类型 '$SHELL_TYPE'"
    echo "支持的类型: bash, zsh, fish"
    echo "用法: $0 [bash|zsh|fish]"
    exit 1
fi

echo "=== 在线安装模式 ==="
echo "Shell 类型: $SHELL_TYPE"
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
bash "$TEMP_SETUP" "$SHELL_TYPE"

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
        echo "用 '\rm file' 可强制使用系统 rm 功能。" >&2
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
        echo "用 '\rm file' 可强制使用系统 rm 功能。" >&2
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
# alias grep="grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}"
alias grep='rg'

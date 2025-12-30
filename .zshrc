###
# Zinit Bootstrap
###
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZINIT%F{220} Flexible Shell Manager%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

###
# Basic Environment
###
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/local/go/bin:/var/lib/flatpak/exports/bin:$PATH"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export EDITOR='nvim' # 默认使用 nvim，如果不存在可能会回退，但在 zinit 之前设置比较好
export HISTSIZE=10000
export HISTFILESIZE=10000
# 建议设置 HISTFILE，Zinit/OMZ 可能会处理，但显式设置更安全
export HISTFILE="$HOME/.zsh_history"

# 编译选项
export ARCHFLAGS="-arch $(uname -m)"

###
# Zinit Plugins
###

# 1. 加载 OMZ 核心库 (Libs)
# OMZ 的库提供了很多基础功能，git, completion 等
zinit wait lucid for \
    OMZL::git.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::completion.zsh \
    OMZL::clipboard.zsh \
    OMZL::directories.zsh \
    OMZL::theme-and-appearance.zsh

# 2. 加载 OMZ 插件
# 注意：docker, nvm 等插件比较重，使用 wait async 加载
zinit wait lucid for \
    OMZP::git \
    OMZP::sudo \
    OMZP::extract \
    OMZP::colored-man-pages \
    OMZP::command-not-found

# Docker & Docker Compose
# 这些插件主要提供补全，lazy load 就可以了
zinit wait lucid for \
    OMZP::docker \
    OMZP::docker-compose

# GH (Github CLI)
zinit wait lucid for OMZP::gh

# NVM - Node Version Manager
# NVM 启动非常慢。这里只延迟加载它。
# 更好的建议：改用 'fnm' (Fast Node Manager) 或 'voltm'。
# 如果必须用 nvm，可以这样配置 lazy load (当输入 node, npm, nvm 时才加载)
# 但 OMZ 的 nvm 插件会尝试自动处理，这里先用 turbo mode 加载插件
zinit wait="1" lucid for OMZP::nvm

# 3. 第三方插件

# Zoxide (更好的 cd)
# 需要系统已安装 zoxide 二进制
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi

# FZF
# 如果通过系统安装了 fzf
if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

# 辅助插件
# 提醒你使用现有的 Alias，帮助养成肌肉记忆
zinit wait lucid for MichaelAquilina/zsh-you-should-use

# FZF-Tab (用 fzf 替换补全菜单)
# 必须在 compinit 之后加载
zinit wait lucid for Aloxaf/fzf-tab

# --- FZF-TAB 配置 ---
# 禁用 sort 当补全 git checkout 时
zstyle ':completion:*:git-checkout:*' sort false
# 设置描述格式
zstyle ':completion:*:descriptions' format '[%d]'
# 启用 ls 颜色
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# 预览目录内容 (使用 eza)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
# 预览文件内容 (使用 bat) - 排除大文件
zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 {}'
# Kill 命令预览进程详情
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap
# --------------------

# Syntax Highlighting & Autosuggestions
# 根据 Zinit 最佳实践，这两个通常放在最后加载
# fast-syntax-highlighting 取代 zsh-syntax-highlighting，性能更好
zinit wait lucid for \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-autosuggestions \
    zsh-users/zsh-history-substring-search

# 适配不同终端的按键映射
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

###
# Theme: Starship
###
# 保持原有的 Starship 配置
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

# [cite_start]载入内置的批量重命名工具 zmv [cite: 1]
autoload -Uz zmv

###
# Custom Settings
###

# 加载自定义 Alias
# Zinit 方式加载：作为 Snippet 加载，使用 wait'1' 确保在 OMZ 插件之后加载，防止 Alias 被覆盖
if [[ -f "$HOME/.aliases" ]]; then
    zinit ice wait"1" lucid
    zinit snippet "$HOME/.aliases"
fi

# 你的远程会话信息显示逻辑
if [[ -f "$HOME/.login_info.sh" ]]; then
    bash "$HOME/.login_info.sh"
fi

# 修正补全相关配置
ZSH_DISABLE_COMPFIX="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="%b %e, %Y"

# 加载补全系统 (Zinit 会自动处理，但有时候需要显式调用来应用某些设置)
# zinit cdreplay -q

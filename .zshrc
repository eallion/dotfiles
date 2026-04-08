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
export EDITOR='nvim'
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTFILE="$HOME/.zsh_history"

# 编译选项
export ARCHFLAGS="-arch $(uname -m)"

###
# Zinit Plugins
###

# 1. 加载 OMZ 核心库 (Libs)
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
zinit wait lucid for \
    OMZP::git \
    OMZP::sudo \
    OMZP::extract \
    OMZP::colored-man-pages \
    OMZP::command-not-found

# Docker & Docker Compose
zinit wait lucid for \
    OMZP::docker \
    OMZP::docker-compose

# GH (Github CLI)
zinit wait lucid for OMZP::gh

# Mise (Version Manager)
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# 3. 第三方插件

# Zoxide (更好的 cd)
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi

# FZF
if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

# 辅助插件
zinit wait lucid for MichaelAquilina/zsh-you-should-use

# FZF-Tab (用 fzf 替换补全菜单)
zinit wait lucid for Aloxaf/fzf-tab

# --- FZF-TAB 配置 ---
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 {}'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap
# --------------------

# Syntax Highlighting & Autosuggestions
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
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

autoload -Uz zmv

###
# Custom Settings
###

# 加载自定义 Alias
if [[ -f "$HOME/.aliases" ]]; then
    zinit ice wait"1" lucid
    zinit snippet "$HOME/.aliases"
fi

# 你的远程会话信息显示逻辑
if [[ -f "$HOME/.login_info.sh" ]]; then
    bash "$HOME/.login_info.sh"
fi

ZSH_DISABLE_COMPFIX="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="%b %e, %Y"

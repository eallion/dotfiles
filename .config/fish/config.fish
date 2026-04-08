if status is-interactive
    set -gx LANG en_US.UTF-8
    set -gx LC_ALL en_US.UTF-8
    set -gx EDITOR nvim
    set -g fish_greeting ""

    fish_add_path -gP $HOME/.local/bin $HOME/bin /usr/local/bin /usr/local/go/bin /var/lib/flatpak/exports/bin

    if test -f $HOME/.login_info.sh
        bash $HOME/.login_info.sh
    end

    if test -f $HOME/.config/fish/functions/aliases.fish
        source $HOME/.config/fish/functions/aliases.fish
    end

    if type -q fzf
        fzf --fish | source
    end

    if type -q starship
        starship init fish | source
    end

    if type -q mise
        mise activate fish | source
    end

    # FYCU - alias 提示
    set -gx FYCU_MESSAGE_POSITION "before"
    set -gx FYCU_ENABLE_ABBR true

    # Autosuggestions - 历史命令自动建议
    set -g fish_autosuggestion_enabled 1
    set -g fish_color_autosuggestion brblack

    # Zoxide - 智能目录跳转
    if type -q zoxide
        zoxide init fish | source
    end
end

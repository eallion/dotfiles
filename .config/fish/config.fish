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
        # 1. 终端定义保护：如果客户端传递 xterm-ghostty 但服务端缺少对应 terminfo，安全回退 TERM 为 xterm-256color 防止应用报错
        if test "$TERM" = "xterm-ghostty"
            if not infocmp -a xterm-ghostty >/dev/null 2>&1
                set -gx TERM xterm-256color
            end
        end

        # 2. Starship 智能主题适配逻辑：
        # 默认使用主配置（如 Gruvbox Rainbow），仅在明确不支持 Nerd Font 的环境自动降级为兼容主题
        set -l is_plain_env false

        # 环境变量显式指定 (支持快捷切换)
        if test -n "$STARSHIP_PLAIN"; and test "$STARSHIP_PLAIN" != "0"
            set is_plain_env true
        # Linux 基础虚拟控制台、串口控制台或无格式终端 (物理控制台 TTY1-6、Proxmox VM noVNC 等)
        else if string match -rq '^(linux|dumb|vt100|vt102|vt220|ansi)$' "$TERM"
            set is_plain_env true
        # VNC 远程桌面环境 (TigerVNC, TightVNC, x11vnc, TurboVNC 等)
        else if test -n "$VNCDESKTOP"; or test -n "$VNC_PORT"; or test -n "$VNC_SOCKET"
            set is_plain_env true
        # 服务端本地图形会话 (有 DISPLAY 但没有 SSH 连接，通常为 VPS 上的 VNC/XRDP 桌面终端)
        else if test -n "$DISPLAY"; and test -z "$SSH_CONNECTION"; and test -z "$SSH_CLIENT"; and test "$TERM" != "xterm-ghostty"
            set is_plain_env true
        # Proxmox / 云厂商 Web 网页控制台 (无 SSH 连接且在非特化 xterm 下运行)
        else if test -z "$SSH_CONNECTION"; and test -z "$SSH_CLIENT"; and string match -rq 'xterm' "$TERM"; and test -z "$COLORTERM"; and test "$TERM" != "xterm-ghostty"
            set is_plain_env true
        end

        # 根据检测结果加载对应主题
        if test "$is_plain_env" = "true"; and test -f $HOME/.config/starship-plain.toml
            set -gx STARSHIP_CONFIG $HOME/.config/starship-plain.toml
        else
            set -e STARSHIP_CONFIG
        end

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
